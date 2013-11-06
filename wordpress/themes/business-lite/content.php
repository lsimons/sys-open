<?php
/**
 * Content Template
 *
 *
 * @category CyberChimps Framework
 * @package  Framework
 * @since    1.0
 * @author   CyberChimps
 * @license  http://www.opensource.org/licenses/gpl-license.php GPL v2.0 (or later)
 * @link     http://www.cyberchimps.com/
 */

?>

<article id="post-<?php the_ID(); ?>" <?php post_class(); ?>>

    <header class="entry-header">

        <?php cyberchimps_post_format_icon(); ?>

        <?php echo ( 'post' == get_post_type() && !is_single() || is_search() ) ? '<h2 class="entry-title">' : '<h1 class="entry-title">'; ?>

        <?php
        if( 'page' == get_post_type() ) :

            // get the page title toggle option
            $page_title = get_post_meta( get_the_ID(), 'cyberchimps_page_title_toggle', true );

            if( is_search() ):
                ?>
                <a href="<?php the_permalink(); ?>" title="<?php printf( esc_attr__( 'Permalink to %s', 'cyberchimps' ), the_title_attribute( 'echo=0' ) ); ?>" rel="bookmark">
                    <?php ( get_the_title() ) ? the_title() : the_permalink(); ?>
                </a>
            <?php
            elseif( $page_title == "1" || $page_title == "" ) :
                ( get_the_title() ) ? the_title() : the_permalink();
            endif;
        else :
            if( 'post' == get_post_type() && is_single() ) :

                // get the post title toggle option
                $post_title = cyberchimps_get_option( 'single_post_title' );
                if( $post_title == "1" ) : ?>
                    <?php ( get_the_title() ) ? the_title() : the_permalink(); ?>
                <?php endif;
            else : ?>
                <a href="<?php the_permalink(); ?>" title="<?php printf( esc_attr__( 'Permalink to %s', 'cyberchimps' ), the_title_attribute( 'echo=0' ) ); ?>"
                   rel="bookmark"><?php ( get_the_title() ) ? the_title() : the_permalink(); ?></a>
            <?php
            endif;
        endif; ?>

        <?php echo ( 'post' == get_post_type() && !is_single() && is_search() ) ? '</h2>' : '</h1>'; ?>

        <?php if( 'post' == get_post_type() ) : ?>
            <div class="entry-meta">
                <?php cyberchimps_posted_on(); ?>
                <?php cyberchimps_posted_by(); ?>
                <?php cyberchimps_post_comments(); ?>
                <?php cyberchimps_posted_in(); ?>

            </div><!-- .entry-meta -->
        <?php endif; ?>
    </header>
    <!-- .entry-header -->

    <?php if( is_single() ) : ?>

        <div class="entry-content">
            <?php cyberchimps_featured_image(); ?>
            <?php the_content( __( 'Continue reading', 'cyberchimps' ) . ' <span class="meta-nav">&rarr;</span>' ); ?>
            <?php wp_link_pages( array( 'before' => '<div class="page-links">' . __( 'Pages:', 'cyberchimps' ), 'after' => '</div>' ) ); ?>
        </div><!-- .entry-content -->

    <?php elseif( is_search() ): ?>
        <div class="entry-summary">
            <?php cyberchimps_featured_image(); ?>
            <?php add_filter( 'excerpt_more', 'cyberchimps_search_excerpt_more', 999 ); ?>
            <?php add_filter( 'excerpt_length', 'cyberchimps_search_excerpt_length', 999 ); ?>
            <?php the_excerpt(); ?>
            <?php remove_filter( 'excerpt_length', 'cyberchimps_search_excerpt_length', 999 ); ?>
            <?php remove_filter( 'excerpt_more', 'cyberchimps_search_excerpt_more', 999 ); ?>
        </div><!-- .entry-summary -->

    <?php
    elseif( is_archive() ): ?>
        <?php if( cyberchimps_get_option( 'archive_post_excerpts' ) ): ?>
            <div class="entry-summary">
                <?php cyberchimps_featured_image(); ?>
                <?php the_excerpt(); ?>
            </div>
        <?php else: ?>
            <div class="entry-content">
                <?php cyberchimps_featured_image(); ?>
                <?php the_content( __( 'Continue reading', 'cyberchimps' ) . ' <span class="meta-nav">&rarr;</span>' ); ?>
                <?php wp_link_pages( array( 'before' => '<div class="page-links">' . __( 'Pages:', 'cyberchimps' ), 'after' => '</div>' ) ); ?>
            </div><!-- .entry-content -->
        <?php endif; ?>

    <?php
    elseif( is_page() ): ?>
        <div class="entry-summary">
            <?php cyberchimps_featured_image(); ?>
            <?php the_content(); ?>
        </div><!-- .entry-summary -->

    <?php
    else : // blog post pages ?>
        <?php if( cyberchimps_get_option( 'post_excerpts' ) ): ?>
            <div class="entry-summary">
                <?php cyberchimps_featured_image(); ?>
                <?php the_excerpt(); ?>
            </div>
        <?php else: ?>
            <div class="entry-content">
                <?php cyberchimps_featured_image(); ?>
                <?php the_content( __( 'Continue reading', 'cyberchimps' ) . ' <span class="meta-nav">&rarr;</span>' ); ?>
                <?php wp_link_pages( array( 'before' => '<div class="page-links">' . __( 'Pages:', 'cyberchimps' ), 'after' => '</div>' ) ); ?>
            </div><!-- .entry-content -->
        <?php endif; ?>

    <?php endif; ?>

    <footer class="entry-meta">
        <?php if( 'post' == get_post_type() ) : // Hide category and tag text for pages on Search ?>

            <?php cyberchimps_post_tags(); ?>

        <?php endif; // End if 'post' == get_post_type() ?>

        <?php edit_post_link( __( 'Edit', 'cyberchimps' ), '<span class="edit-link">', '</span>' ); ?>

    </footer>
    <!-- #entry-meta -->

</article><!-- #post-<?php the_ID(); ?> -->