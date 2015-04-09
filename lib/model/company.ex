defmodule Corpcrawl.Model.Company do
  use Ecto.Model
  @primary_key {:cik, :integer, [:unique]}
  
  schema "company" do
    field :name
  end


  def create(company) do
    Corpcrawl.Repo.insert company
  end

  def get(cik) do
    Corpcrawl.Repo.get(__MODULE__, cik)
  end

  def get_or_create(%__MODULE__{cik: cik} = c) do
    case get(cik) do
      nil -> create(c)
      res -> res
    end
  end
end