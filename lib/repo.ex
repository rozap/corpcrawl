defmodule Corpcrawl.Repo do
  use Ecto.Repo, 
    otp_app: :corpcrawl,  
    adapter: Ecto.Adapters.Postgres
end