defmodule Corpcrawl.Model.Subsidiary do
  use Ecto.Model
  alias Corpcrawl.Model.Company
  alias Corpcrawl.Model.Filing

  schema "subsidiary" do
  	field :name
  	field :location
  	belongs_to :filing, Filing
  end

  def create(filing, s) do
  	sub = struct(__MODULE__, s) |> struct(filing_id: filing.id)
  	IO.puts "    - #{s.name}"
  	Corpcrawl.Repo.insert(sub)
  end
end