# infra/config/routes/web_routes.rb

require_root 'adapter-intake/web-app/request/home_web_adapter'




Web = WebRouter.draw do
  GET '/', to: [HomeWebAdapter, :home_page]
end