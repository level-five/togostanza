TogoStanza::Application.routes.draw do
  root to: 'demo#index'

  resources :stanza, only: %w(index show) do
    get :help
  end
end
