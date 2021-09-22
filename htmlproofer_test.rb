require 'html-proofer'

options = {
  assume_extension: true,
  check_img_http: true,
  check_html: true,
  empty_alt_ignore: true,
  disable_external: false,
  allow_hash_href: true,
  check_opengraph: true,
  only_4xx: true,
  http_status_ignore: [429,403],
  url_ignore: [ /github.com.*okd-virtualization.*edit.*/ ],
  parallel: { in_processes: 8 },
  cache: { timeframe: '6w' },
}

HTMLProofer.check_directory("./_site", options).run
