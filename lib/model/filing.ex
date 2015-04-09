defmodule Corpcrawl.Model.Filing do
  use Ecto.Model
  alias Corpcrawl.Model.Company

  schema "filing" do

    field :form_type
    field :date_filed
    field :file_name
    belongs_to :company, Company
  end


  def get_or_create(filing) do
    existing = from(
      f in __MODULE__, 
      where: f.file_name == ^filing.file_name,
      select: f) |> Corpcrawl.Repo.all

    case existing do
      [] -> Corpcrawl.Repo.insert filing
      [e] -> e
      _ -> raise "Duplicate filing #{filing.form_type} 
                  for company #{filing.company} on #{filing.date_filed}"
    end
  end

  def insert_many(filings) do
    Enum.map(filings, fn filing ->
      c = %Company{name: filing.company_name, cik: String.to_integer(filing.cik)}
      company = Company.get_or_create(c)

      f = struct(
        struct(__MODULE__, filing), 
        company: company, 
        company_id: company.cik
      )

      # IO.puts "CREATE #{inspect f}"
      get_or_create f
    end)
  end
end