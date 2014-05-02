Rails.application.routes.draw do
  scope :module => :staypuft do
    resources :deployments do
      collection do
        get 'auto_complete_search'
        post 'associate_host'
      end
      member do
        get 'deploy'
        get 'populate'
        get 'summary'
        get 'cancel'
      end
    end

    resources :deployment_steps
  end
end
