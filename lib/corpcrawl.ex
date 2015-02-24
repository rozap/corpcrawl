defmodule Corpcrawl do
  alias Edgarex.Fetcher, as: Fetcher
  alias Edgarex.FTPStream, as: FTP
  alias Exquery.Query, as: Q
  
  def get_10ks(year, quarter) do
    Fetcher.form(year, quarter)
    |> Stream.filter(fn entry ->
      entry.form_type == "10-K"
    end)
  end

  def get_ex221(form_10ks, concurrency) do
    form_10ks
    |> Enum.map(fn form ->
      IO.puts "from uri #{form.file_name}"
      {form, FTP.from_uri(form.file_name)}
    end)
    |> Enum.chunk(concurrency, concurrency, [])
    |> Enum.flat_map(fn chunk -> load_chunk(chunk) end)
  end


  def load_chunk(chunk) do
    chunk
    |> Enum.to_list
    |> Enum.map(fn fm ->
      {fm, Task.async(fn ->
        load_ex221(fm)
      end)}
    end)
    |> Enum.map(fn {fm, task} -> 
      try do
        Task.await(task, 30_000) 
      catch
        :exit, {:timeout, e} -> 
          IO.puts("Failure #{inspect e} for #{inspect fm}")
          {:timeout, nil}
      end
    end)
    |> Enum.map(fn res ->
        case res do
          {_form, nil} -> []
          {form, doc} -> 
            [doc] = doc
            |> List.wrap
            |> Edgarex.Docparser.doc_trees
        
            {form, doc}
        end
      end)
    |> List.flatten

  end

  defp load_ex221({form, ftp_stream}) do
    ex221 = ftp_stream
    |> Enum.into("")
    |> Edgarex.Docparser.to_documents
    |> Enum.find(fn doc ->
      doc.type == "EX-21.1"
    end)
    {form, ex221}
  end


  defp filter_nbsp(els) do
    els
    |> Enum.map(fn {:text, contents, attrs} ->
      {:text, String.replace(contents, "&nbsp;", ""), attrs}
    end)
    |> Enum.filter(fn {_, c, _} ->
      c != ""
    end)
  end

  defp contents({:text, contents, _}), do: contents

  def find_subsidiaries(ex22s) do
    ex22s
    |> Enum.map(fn {form, doc} ->
      [header | subs] = Q.all(doc.tree, {:tag, "tr", []})
      |> Enum.map(fn row ->
        row
        |> List.wrap
        |> Q.all({:text, :any, []})
        |> filter_nbsp
      end)
      |> List.flatten
      |> Enum.chunk(2)
      |> Enum.reject(fn [a, b] ->
        (String.length(contents(a)) < 3) || (String.length(contents(b)) < 3)
      end)
  
      header = Enum.map(header, fn h -> contents(h) end)

      subs = Enum.map(subs, fn chunk ->
        chunk = Enum.map(chunk, fn c -> contents(c) end)
        Enum.zip(header, chunk)
        |> Enum.into(%{})
      end)
      |> List.flatten

      IO.puts "Company #{form.company_name}"
      IO.each(subs, fn s ->
        IO.puts "    - #{inspect s}"
      end)


      {form, subs}
    end)

  end

end
