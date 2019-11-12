=begin
 # kses 0.2.2 - HTML/XHTML filter that only allows some elements and attributes
 # Copyright (C) 2002, 2003, 2005  Ulf Harnhammar
 #
 # This program is free software and open source software; you can redistribute
 # it and/or modify it under the terms of the GNU General Public License as
 # published by the Free Software Foundation; either version 2 of the License,
 # or (at your option) any later version.
 #
 # This program is distributed in the hope that it will be useful, but WITHOUT
 # ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 # FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
 # more details.
 #
 # You should have received a copy of the GNU General Public License along
 # with this program; if not, write to the Free Software Foundation, Inc.,
 # 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA
 # http://www.gnu.org/licenses/gpl.html
 #
 # [kses strips evil scripts!]
 #
 # Added wp_ prefix to avoid conflicts with existing kses users
 #
 # @version 0.2.2
 # @copyright (C) 2002, 2003, 2005
 # @author Ulf Harnhammar <http://advogato.org/person/metaur/>
 *
 * file wp-includes\kses.php
=end
module Railspress::KsesHelper

  # ALLOWED_ENTITY_NAMES Array of KSES allowed HTML entitity names.
  ALLOWED_ENTITY_NAMES = [
      'nbsp',
      'iexcl',
      'cent',
      'pound',
      'curren',
      'yen',
      'brvbar',
      'sect',
      'uml',
      'copy',
      'ordf',
      'laquo',
      'not',
      'shy',
      'reg',
      'macr',
      'deg',
      'plusmn',
      'acute',
      'micro',
      'para',
      'middot',
      'cedil',
      'ordm',
      'raquo',
      'iquest',
      'Agrave',
      'Aacute',
      'Acirc',
      'Atilde',
      'Auml',
      'Aring',
      'AElig',
      'Ccedil',
      'Egrave',
      'Eacute',
      'Ecirc',
      'Euml',
      'Igrave',
      'Iacute',
      'Icirc',
      'Iuml',
      'ETH',
      'Ntilde',
      'Ograve',
      'Oacute',
      'Ocirc',
      'Otilde',
      'Ouml',
      'times',
      'Oslash',
      'Ugrave',
      'Uacute',
      'Ucirc',
      'Uuml',
      'Yacute',
      'THORN',
      'szlig',
      'agrave',
      'aacute',
      'acirc',
      'atilde',
      'auml',
      'aring',
      'aelig',
      'ccedil',
      'egrave',
      'eacute',
      'ecirc',
      'euml',
      'igrave',
      'iacute',
      'icirc',
      'iuml',
      'eth',
      'ntilde',
      'ograve',
      'oacute',
      'ocirc',
      'otilde',
      'ouml',
      'divide',
      'oslash',
      'ugrave',
      'uacute',
      'ucirc',
      'uuml',
      'yacute',
      'thorn',
      'yuml',
      'quot',
      'amp',
      'lt',
      'gt',
      'apos',
      'OElig',
      'oelig',
      'Scaron',
      'scaron',
      'Yuml',
      'circ',
      'tilde',
      'ensp',
      'emsp',
      'thinsp',
      'zwnj',
      'zwj',
      'lrm',
      'rlm',
      'ndash',
      'mdash',
      'lsquo',
      'rsquo',
      'sbquo',
      'ldquo',
      'rdquo',
      'bdquo',
      'dagger',
      'Dagger',
      'permil',
      'lsaquo',
      'rsaquo',
      'euro',
      'fnof',
      'Alpha',
      'Beta',
      'Gamma',
      'Delta',
      'Epsilon',
      'Zeta',
      'Eta',
      'Theta',
      'Iota',
      'Kappa',
      'Lambda',
      'Mu',
      'Nu',
      'Xi',
      'Omicron',
      'Pi',
      'Rho',
      'Sigma',
      'Tau',
      'Upsilon',
      'Phi',
      'Chi',
      'Psi',
      'Omega',
      'alpha',
      'beta',
      'gamma',
      'delta',
      'epsilon',
      'zeta',
      'eta',
      'theta',
      'iota',
      'kappa',
      'lambda',
      'mu',
      'nu',
      'xi',
      'omicron',
      'pi',
      'rho',
      'sigmaf',
      'sigma',
      'tau',
      'upsilon',
      'phi',
      'chi',
      'psi',
      'omega',
      'thetasym',
      'upsih',
      'piv',
      'bull',
      'hellip',
      'prime',
      'Prime',
      'oline',
      'frasl',
      'weierp',
      'image',
      'real',
      'trade',
      'alefsym',
      'larr',
      'uarr',
      'rarr',
      'darr',
      'harr',
      'crarr',
      'lArr',
      'uArr',
      'rArr',
      'dArr',
      'hArr',
      'forall',
      'part',
      'exist',
      'empty',
      'nabla',
      'isin',
      'notin',
      'ni',
      'prod',
      'sum',
      'minus',
      'lowast',
      'radic',
      'prop',
      'infin',
      'ang',
      'and',
      'or',
      'cap',
      'cup',
      'int',
      'sim',
      'cong',
      'asymp',
      'ne',
      'equiv',
      'le',
      'ge',
      'sub',
      'sup',
      'nsub',
      'sube',
      'supe',
      'oplus',
      'otimes',
      'perp',
      'sdot',
      'lceil',
      'rceil',
      'lfloor',
      'rfloor',
      'lang',
      'rang',
      'loz',
      'spades',
      'clubs',
      'hearts',
      'diams',
      'sup1',
      'sup2',
      'sup3',
      'frac14',
      'frac12',
      'frac34',
      'there4',
  ]

  # Sanitizes a string and removed disallowed URL protocols.
  #
  # This function removes all non-allowed protocols from the beginning of the
  # string. It ignores whitespace and the case of the letters, and it does
  # understand HTML entities. It does its work recursively, so it won't be
  # fooled by a string like `javascript:javascript:alert(57)`.
  #
  # @param [string]   string            Content to filter bad protocols from.
  # @param [Array]    allowed_protocols Array of allowed URL protocols.
  # @return [string] Filtered content.
  def wp_kses_bad_protocol(string, allowed_protocols)
    # TODO finish
    # string     = wp_kses_no_null($string)
    # iterations = 0
    #
    # do {
    # 	$original_string = $string;
    # 	$string          = wp_kses_bad_protocol_once( $string, $allowed_protocols );
    # } while ( $original_string != $string && ++$iterations < 6 );
    #
    # if ( $original_string != $string ) {
    # 	return '';
    # }
    string
  end

  # Converts and fixes HTML entities.
  #
  # This function normalizes HTML entities. It will convert `AT&T` to the correct
  # `AT&amp;T`, `&#00058;` to `&#58;`, `&#XYZZY;` to `&amp;#XYZZY;` and so on.
  #
  # @param [string] string Content to normalize entities.
  # @return [string] Content with normalized entities.
  def wp_kses_normalize_entities(string)
    # Disarm all entities by converting & to &amp;
    string = string.gsub('&', '&amp;')

    # Change back the allowed entities in our entity whitelist
    string = string.gsub(/&amp;([A-Za-z]{2,8}[0-9]{0,2});/){ |match| wp_kses_named_entities(match.match(/&amp;([A-Za-z]{2,8}[0-9]{0,2});/)) }
    string = string.gsub(/(?<=&amp;#)(0*[0-9]{1,7})(?=;)/){ |match| wp_kses_normalize_entities2(match.match(/&amp;#(0*[0-9]{1,7});/)) }
    string = string.gsub(/(?<=&amp;#[Xx])(0*[0-9A-Fa-f]{1,6})(?=;)/){ |match| wp_kses_normalize_entities3(match.match(/&amp;#[Xx](0*[0-9A-Fa-f]{1,6});/)) }
    string
  end

  # Callback for `wp_kses_normalize_entities()` regular expression.
  #
  # This function only accepts valid named entity references, which are finite,
  # case-sensitive, and highly scrutinized by HTML and XML validators.
  #
  # @global array $allowedentitynames
  #
  # @param [array] matches preg_replace_callback() matches array.
  # @return [string] Correctly encoded entity.
  def wp_kses_named_entities(matches)
    # TODO global $allowedentitynames;

    return '' if matches[1].blank?

    i = matches[1]
    ALLOWED_ENTITY_NAMES.include?(i) ? "&#{i};" : "&amp;#{i};"
  end

  # Callback for `wp_kses_normalize_entities()` regular expression.
  #
  # This function helps `wp_kses_normalize_entities()` to only accept 16-bit
  # values and nothing more for `&#number;` entities.
  #
  # @access private
  #
  # @param [array] matches `preg_replace_callback()` matches array.
  # @return [string] Correctly encoded entity.
  def wp_kses_normalize_entities2(matches)
    return '' if matches[1].empty?

    i = matches[1]
    if valid_unicode(i)
      i = i.gsub(/^0+/, '').rjust(3, '0')
      "&##{i};"
    else
      "&amp;##{i};"
    end
  end

  # Callback for `wp_kses_normalize_entities()` for regular expression.
  #
  # This function helps `wp_kses_normalize_entities()` to only accept valid Unicode
  # numeric entities in hex form.
  #
  # @access private
  # @ignore
  #
  # @param [array] matches `preg_replace_callback()` matches array.
  # @return [string] Correctly encoded entity.
  def wp_kses_normalize_entities3(matches)
    return '' if matches[1].empty?
    hexchars = matches[1]
    valid_unicode(hexchars.to_i(16)) ?  '&#x' + hexchars.gsub(/^0+/, '') + ';' : "&amp;#x#{hexchars};"
  end

  # Determines if a Unicode codepoint is valid.
  #
  # @param [int] i Unicode codepoint.
  # @return bool Whether or not the codepoint is a valid Unicode codepoint.
  def valid_unicode(i)
    (i == 0x9 || i == 0xa || i == 0xd ||
        (i >= 0x20 && i <= 0xd7ff) ||
        (i >= 0xe000 && i <= 0xfffd) ||
        (i >= 0x10000 && i <= 0x10ffff))
  end

end