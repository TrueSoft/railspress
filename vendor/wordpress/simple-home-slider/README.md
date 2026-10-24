# Simple Home Slider

This plugin creates a minimal WordPress custom post type called `homepage_slide`.

## What it stores
Each slide can include:
- featured image
- title
- text content (`post_content`)
- a numeric order value
- an optional link

## What it does not do
It does not generate front-end HTML or output slider markup. It only stores the slide data and exposes it via a helper function:

```php
$slides = simple_home_slider_get_slides();
```

This returns an array like:

```php
[
    [
        'id' => 42,
        'title' => 'Example slide',
        'content' => '<p>Some text</p>',
        'image_id' => 101,
        'image_url' => 'https://example.com/image.jpg',
        'link' => 'https://example.com/target',
        'order' => 1,
    ],
]
```

## Usage
1. Activate the plugin in WordPress.
2. Go to `Homepage Slides` in the admin menu.
3. Add slides.
4. Set the featured image, content, order, and optional link.
5. Use the returned data in your theme or front-end code.

## File location
`vendor/wordpress/simple-home-slider/simple-home-slider.php`
