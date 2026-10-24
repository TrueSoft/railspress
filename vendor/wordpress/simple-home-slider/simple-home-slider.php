<?php
/**
 * Plugin Name: Simple Home Slider
 * Plugin URI: https://example.com/simple-home-slider
 * Description: Minimal WordPress plugin for homepage slide data. It stores slide information in the admin and exposes it as plain data for the theme or app to render however it wants.
 * Version: 1.0.0
 * Author: Railspress
 * License: MIT
 */

if (!defined('ABSPATH')) {
    exit;
}

final class Simple_Home_Slider {
    private const REQUIRED_WIDTH = 1920;
    private const REQUIRED_HEIGHT = 600;

    private static $instance = null;

    public static function instance() {
        if (null === self::$instance) {
            self::$instance = new self();
        }

        return self::$instance;
    }

    private function __construct() {
        add_action('init', [$this, 'register_post_type']);
        add_action('add_meta_boxes', [$this, 'register_meta_boxes']);
        add_action('save_post_homepage_slide', [$this, 'save_slide_meta'], 10, 1);
        add_action('admin_notices', [$this, 'render_admin_notice']);
    }

    public function register_post_type() {
        register_post_type('homepage_slide', [
            'labels' => [
                'name' => 'Homepage Slides',
                'singular_name' => 'Homepage Slide',
                'add_new_item' => 'Add New Slide',
                'edit_item' => 'Edit Slide',
                'new_item' => 'New Slide',
                'view_item' => 'View Slide',
                'search_items' => 'Search Slides',
                'not_found' => 'No slides found',
                'not_found_in_trash' => 'No slides found in Trash',
            ],
            'public' => false,
            'show_ui' => true,
            'show_in_menu' => true,
            'menu_icon' => 'dashicons-images-alt2',
            'supports' => ['title', 'editor', 'thumbnail'],
            'has_archive' => false,
            'rewrite' => false,
            'show_in_rest' => true,
        ]);
    }

    public function register_meta_boxes() {
        add_meta_box(
            'simple_home_slider_box',
            'Slide Settings',
            [$this, 'render_meta_box'],
            'homepage_slide',
            'normal',
            'default'
        );
    }

    public function render_meta_box($post) {
        wp_nonce_field('simple_home_slider_save', 'simple_home_slider_nonce');

        $order = get_post_meta($post->ID, '_simple_home_slider_order', true);
        $link = get_post_meta($post->ID, '_simple_home_slider_link', true);
        ?>
        <p>
            <label for="simple_home_slider_order"><strong>Order</strong></label><br>
            <input
                type="number"
                id="simple_home_slider_order"
                name="simple_home_slider_order"
                value="<?php echo esc_attr((string) $order); ?>"
                min="0"
                step="1"
                class="widefat"
            >
        </p>

        <p>
            <label for="simple_home_slider_link"><strong>Link (optional)</strong></label><br>
            <input
                type="url"
                id="simple_home_slider_link"
                name="simple_home_slider_link"
                value="<?php echo esc_attr($link); ?>"
                placeholder="https://example.com"
                class="widefat"
            >
        </p>

        <p class="description">
            Required image size: <?php echo self::REQUIRED_WIDTH; ?>x<?php echo self::REQUIRED_HEIGHT; ?> pixels.
        </p>
        <?php
    }

    public function save_slide_meta($post_id) {
        if (!isset($_POST['simple_home_slider_nonce']) || !wp_verify_nonce($_POST['simple_home_slider_nonce'], 'simple_home_slider_save')) {
            return;
        }

        if (defined('DOING_AUTOSAVE') && DOING_AUTOSAVE) {
            return;
        }

        $image_id = !empty($_POST['_thumbnail_id']) ? absint($_POST['_thumbnail_id']) : get_post_thumbnail_id($post_id);

        if (!$image_id) {
            return;
        }

        $meta = wp_get_attachment_metadata($image_id);

        if (!is_array($meta) || empty($meta['width']) || empty($meta['height'])) {
            return;
        }

        if ((int) $meta['width'] !== self::REQUIRED_WIDTH || (int) $meta['height'] !== self::REQUIRED_HEIGHT) {
            delete_post_thumbnail($post_id);

            wp_safe_redirect(
                add_query_arg(
                    'simple_home_slider_error',
                    'size',
                    admin_url('post.php?post=' . $post_id . '&action=edit')
                )
            );
            exit;
        }

        if (isset($_POST['simple_home_slider_order'])) {
            $order = absint($_POST['simple_home_slider_order']);
            if ($order > 0 || '0' === $_POST['simple_home_slider_order']) {
                update_post_meta($post_id, '_simple_home_slider_order', $order);
            }
        }

        if (isset($_POST['simple_home_slider_link'])) {
            $link = esc_url_raw(trim($_POST['simple_home_slider_link']));

            if ('' === $link) {
                delete_post_meta($post_id, '_simple_home_slider_link');
            } else {
                update_post_meta($post_id, '_simple_home_slider_link', $link);
            }
        }
    }

    public function render_admin_notice() {
        if (isset($_GET['simple_home_slider_error']) && 'size' === $_GET['simple_home_slider_error']) {
            echo '<div class="notice notice-error is-dismissible"><p><strong>Homepage slide image error:</strong> The featured image must be exactly 1920x600 pixels.</p></div>';
        }
    }

    public static function get_slides($limit = -1) {
        $query = new WP_Query([
            'post_type' => 'homepage_slide',
            'post_status' => 'publish',
            'posts_per_page' => $limit,
            'meta_key' => '_simple_home_slider_order',
            'orderby' => 'meta_value_num',
            'order' => 'ASC',
            'meta_type' => 'NUMERIC',
            'ignore_sticky_posts' => true,
        ]);

        $slides = [];

        foreach ($query->posts as $post) {
            $image_id = get_post_thumbnail_id($post->ID);

            $slides[] = [
                'id' => $post->ID,
                'title' => $post->post_title,
                'content' => apply_filters('the_content', $post->post_content),
                'image_id' => $image_id,
                'image_url' => $image_id ? wp_get_attachment_image_url($image_id, 'full') : '',
                'link' => get_post_meta($post->ID, '_simple_home_slider_link', true),
                'order' => (int) get_post_meta($post->ID, '_simple_home_slider_order', true),
            ];
        }

        return $slides;
    }
}

Simple_Home_Slider::instance();

if (!function_exists('simple_home_slider_get_slides')) {
    function simple_home_slider_get_slides($limit = -1) {
        return Simple_Home_Slider::get_slides($limit);
    }
}
