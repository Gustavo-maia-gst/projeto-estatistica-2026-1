-- Filtro Lua: converte fenced divs com classes customizadas
-- em ambientes tcolorbox para saída LaTeX, e desabilita
-- booktabs para contornar bug no TeX Live 2026.

local envmap = {
  callout        = "calloutbox",
  warning        = "warningbox",
  checkpoint     = "checkpointbox",
  decision       = "decisionbox",
  ["teacher-note"] = "teachernotebox",
}

function Div(el)
  for _, cls in ipairs(el.classes) do
    local env = envmap[cls]
    if env then
      if FORMAT:match("latex") or FORMAT:match("pdf") then
        local open  = pandoc.RawBlock("latex", "\\begin{" .. env .. "}")
        local close = pandoc.RawBlock("latex", "\\end{" .. env .. "}")
        local blocks = pandoc.List({open})
        blocks:extend(el.content)
        blocks:insert(close)
        return blocks
      end
    end
  end
  return el
end

-- Desabilitar booktabs em tabelas pandoc para evitar bug \cmrsideswitch
function Table(tbl)
  if FORMAT:match("latex") or FORMAT:match("pdf") then
    -- Pandoc 3.x: desabilitar "booktabs style" nas tabelas
    if tbl.attr then
      tbl.attr.classes:insert("no-booktabs")
    end
  end
  return tbl
end

-- Remover \usepackage{booktabs} e substituir comandos booktabs no LaTeX raw
function RawBlock(el)
  if el.format == "latex" then
    -- Substituir comandos booktabs por equivalentes simples
    el.text = el.text:gsub("\\toprule%s*\\noalign%s*{}", "\\hline")
    el.text = el.text:gsub("\\midrule%s*\\noalign%s*{}", "\\hline")
    el.text = el.text:gsub("\\bottomrule%s*\\noalign%s*{}", "\\hline")
    el.text = el.text:gsub("\\toprule", "\\hline")
    el.text = el.text:gsub("\\midrule", "\\hline")
    el.text = el.text:gsub("\\bottomrule", "\\hline")
    el.text = el.text:gsub("\\addlinespace[^\n]*", "")
  end
  return el
end
