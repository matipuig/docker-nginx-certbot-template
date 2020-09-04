<?php
/*
Plugin Name: Remove WordPress Version Number
Plugin URI:  https://www.inthiscode.com/
Description: Remove wordpress version number from your website to leave behind any footprint. No one would able to track which wordpress version you are using.
Version:     1.4.1
Author:      InThisCode
Author URI:  http://www.inthiscode.com/
License:     GPL2
License URI: https://www.gnu.org/licenses/gpl-2.0.html
Text Domain: rwvn-itc
*/
defined( 'ABSPATH' ) or die( 'Where are you going?' );

// Admin menu
add_action( 'admin_menu', 'rwvn_itc_add_admin_menu' ); // Add Admin Menu
function rwvn_itc_add_admin_menu(  ) { 
	add_options_page( 'Remove WordPress Version Number', 'Remove Version Number', 'manage_options', 'rwvn_itc', 'rwvn_itc_options_page' );
}
function rwvn_itc_options_page(  ) { 
	?>
	<form action='options.php' method='post'>
		<h1>Remove Version Number</h1>
		<?php
		settings_fields( 'rwvn_itc_pluginPage' );
		do_settings_sections( 'rwvn_itc_pluginPage' );
		submit_button();
		?>
	</form>
	<?php
}

// Admin Settings Initialization
add_action( 'admin_init', 'rwvn_itc_settings_init' );  // Admin setting initialization
function rwvn_itc_settings_init() {
	register_setting( 'rwvn_itc_pluginPage', 'rwvn_itc_settings' );
	
	// Add section
	add_settings_section('rwvn_itc_pluginPage_section', __( 'General Settings', 'rwvn-itc' ), 'rwvn_itc_settings_section_callback', 'rwvn_itc_pluginPage');
	
	// Enable the plugin
	add_settings_field('rwvn_itc_enable', __( 'Enable Plugin', 'rwvn-itc' ), 'rwvn_itc_enable_render', 'rwvn_itc_pluginPage', 'rwvn_itc_pluginPage_section');
}

// Callback
function rwvn_itc_settings_section_callback(  ) { 
	echo __( '', 'rwvn-itc' );
}
$rwvn_itc_options = get_option( 'rwvn_itc_settings' );

// Display enable checkbox
function rwvn_itc_enable_render() {
	global $rwvn_itc_options;
	?>
    <input type='checkbox' name='rwvn_itc_settings[rwvn_itc_enable]' <?php  if ( isset( $rwvn_itc_options['rwvn_itc_enable'] ) && $rwvn_itc_options['rwvn_itc_enable'] == '1' ) {echo 'Checked';} else {echo 'Unchecked'; } ?> value='1'>
    <?php
}

// Add settings link
function rwvn_itc_plugin_settings_link( $links ) {
    $settings_link = '<a href="admin.php?page=rwvn_itc">' . __( 'Settings' ) . '</a>';
    array_push( $links, $settings_link );
  	return $links;
}
$plugin = plugin_basename( __FILE__ );
add_filter( "plugin_action_links_$plugin", 'rwvn_itc_plugin_settings_link' );

// Hide version number
if ( isset( $rwvn_itc_options['rwvn_itc_enable'] ) && $rwvn_itc_options['rwvn_itc_enable'] == '1' ) {
	function rwvn_itc_remove_version() {
		return '';
	}
add_filter('the_generator', 'rwvn_itc_remove_version');
	
// remove wp version param from any enqueued scripts
function rwvn_itc_remove_wp_ver_css_js( $rwvn_itc_src ) {
	global $wp_version;
	if ( strpos( $rwvn_itc_src, '?ver=' ) )
		$rwvn_itc_src = remove_query_arg( 'ver', $rwvn_itc_src );
		return $rwvn_itc_src;
	}
	add_filter( 'style_loader_src', 'rwvn_itc_remove_wp_ver_css_js', 9999 );
	add_filter( 'script_loader_src', 'rwvn_itc_remove_wp_ver_css_js', 9999 );
}