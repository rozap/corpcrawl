defmodule Corpcrawl do
  alias Edgarex.Fetcher, as: Fetcher
  alias Edgarex.FTPStream, as: FTP
  alias Exquery.Query, as: Q
  
  @ignore_tokens ["&nbsp;", "&#160;", "*"]

  def get_10ks(year, quarter) do
    Fetcher.form(year, quarter)
    |> Stream.filter(fn entry ->
      entry.form_type == "10-K"
    end)
  end

  def ten_k_to_subs(form_10ks, concurrency) do
    form_10ks
    |> Enum.map(fn form ->
      # IO.puts "from uri #{form.file_name}"
      {form, FTP.from_uri(form.file_name)}
    end)
    |> Enum.chunk(concurrency, concurrency, [])
    |> Enum.flat_map(fn forms -> load_forms(forms) end)
  end

  defp load_ex221({form, ftp_stream}) do
    ex221 = ftp_stream
    |> Enum.into("")
    |> Edgarex.Docparser.to_documents
    |> Enum.find(fn doc ->
      String.contains?(doc.type, "EX-21")
    end)

    {form, ex221}
  end


  def load_forms(forms) do
    forms
    |> Enum.map(fn form ->
      {form, Task.async(fn -> load_ex221(form) end)}
    end)
    |> Enum.map(fn {form, task} -> 
      try do
        Task.await(task, 60_000) 
      catch
        :exit, {:timeout, e} -> 
          IO.puts("Failure #{inspect e} for #{inspect form}")
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
        
            find_subsidiaries({form, doc})
        end
      end)
    |> List.flatten

  end




  defp clean_ugliness(els) do
    els
    |> Enum.map(fn {:text, contents, attrs} ->
      
      {:ok, re} = @ignore_tokens
      |> Enum.join("|")
      |> Regex.compile

      {:text, Regex.replace(re, contents, ""), attrs}
    end)
    |> Enum.filter(fn {_, c, _} ->
      c != ""
    end)
  end

  defp contents({:text, contents, _}), do: contents



  defp extract_meta(enumerated, :tr) do
    [header | subs] = enumerated
    |> Enum.chunk(2)
    |> Enum.reject(fn [a, b] ->
      (String.length(contents(a)) < 3) || (String.length(contents(b)) < 3)
    end)

    header = Enum.map(header, fn h -> contents(h) end)

    subs = Enum.map(subs, fn [name, location] ->
      %{
        name: contents(name),
        location: contents(location)
      }
    end)
    |> List.flatten

  end

  defp extract_meta(enumerated, :p) do
    Enum.map(enumerated, fn {:text, name, _} ->
      %{name: name}
    end)
  end

  defp extract_text(enumerated, kind) do
    enumerated
    |> Enum.map(fn row ->
      row
      |> List.wrap
      |> Q.all({:text, :any, []})
      |> clean_ugliness
    end)
    |> List.flatten
    |> extract_meta(kind)
  end

  defp find_enumerated(doc) do
    trs = Q.all(doc.tree, {:tag, "tr", []})
    if(length(trs) > 1) do
      extract_text(trs, :tr)
    else
      ps = Q.all(doc.tree, {:tag, "p",  []})
      extract_text(ps, :p)
    end
  end


  def find_subsidiaries({form, doc}) do
    subs = find_enumerated(doc)
    # IO.puts "Company #{form.company_name}"
    # Enum.each(subs, fn s ->
    #   IO.puts "    - #{inspect s}"
    # end)
    {form, subs}
  end

end
