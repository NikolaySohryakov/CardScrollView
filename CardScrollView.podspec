Pod::Spec.new do |s|
  s.name         = "CardScrollView"
  s.version      = "1.0.0"
  s.summary      = "A custom UIScrollView that enables vertical paging without limiting the page height."
  s.description  = <<-DESC
                    A custom UIScrollView that enables vertical paging without limiting the page height and wors the same way as UITableView.
                   DESC
  s.homepage     = "https://github.com/NikolaySohryakov/CardScrollView"
  s.license      = { :type => 'MIT', :file => 'LICENSE' }
  s.author       = { "Nikolay Sohryakov" => "nikolay.sohryakov@gmail.com" }
  s.source       = { :git => "https://github.com/NikolaySohryakov/CardScrollView.git", :tag => s.version }
  s.platform     = :ios, '9.0'
  s.source_files = 'CardScrollView/Source', '*.{swift}'
  s.requires_arc = true
  s.social_media_url = 'https://twitter.com/nsohryakov'
end
