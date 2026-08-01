#!/usr/bin/env Rscript
# Script para gerar o PDF do relatório.
# Contorna bug do booktabs no TeX Live 2026 (cmrsideswitch indefinido).
#
# Uso: Rscript render_pdf.R
#   ou no RStudio: source("render_pdf.R")

Sys.setenv(RSTUDIO_PANDOC = "/usr/lib/rstudio/resources/app/bin/quarto/bin/tools/x86_64")

tex_file <- "tutorial_regressao_multipla_credit.tex"
pdf_file <- "tutorial_regressao_multipla_credit.pdf"

# Etapa 1: Renderizar Rmd -> .tex (pode falhar na compilação LaTeX)
tryCatch(
  rmarkdown::render(
    "tutorial_regressao_multipla_credit.Rmd",
    output_format = rmarkdown::pdf_document(
      toc = FALSE,
      number_sections = TRUE,
      fig_caption = TRUE,
      latex_engine = "pdflatex",
      keep_tex = TRUE,
      includes = rmarkdown::includes(in_header = "preamble-abnt.tex"),
      pandoc_args = c("--lua-filter=filtro-divs.lua")
    )
  ),
  error = function(e) {
    message("Compilacao LaTeX falhou (esperado - bug booktabs). Corrigindo...")
  }
)

# Etapa 2: Se o .tex existe mas o PDF nao, corrigir e recompilar
if (file.exists(tex_file) && !file.exists(pdf_file)) {
  tex <- readLines(tex_file)

  # Substituir comandos booktabs problemáticos
  tex <- gsub("\\\\toprule\\\\noalign\\{\\}", "\\\\hline", tex)
  tex <- gsub("\\\\midrule\\\\noalign\\{\\}", "\\\\hline", tex)
  tex <- gsub("\\\\bottomrule\\\\noalign\\{\\}", "\\\\hline", tex)
  tex <- gsub("\\\\toprule", "\\\\hline", tex)
  tex <- gsub("\\\\midrule", "\\\\hline", tex)
  tex <- gsub("\\\\bottomrule", "\\\\hline", tex)
  tex <- gsub("\\\\addlinespace.*$", "", tex)

  writeLines(tex, tex_file)

  # Compilar com pdflatex (2 passadas para referências cruzadas)
  system2("pdflatex", c("-interaction=nonstopmode", tex_file), stdout = FALSE)
  system2("pdflatex", c("-interaction=nonstopmode", tex_file), stdout = FALSE)

  # Limpar auxiliares
  base <- tools::file_path_sans_ext(tex_file)
  for (ext in c(".aux", ".log", ".out", ".toc", ".lof", ".lot", ".tex",
                ".nav", ".snm", ".vrb")) {
    f <- paste0(base, ext)
    if (file.exists(f)) file.remove(f)
  }
}

if (file.exists(pdf_file)) {
  message("PDF gerado com sucesso: ", pdf_file)
} else {
  message("ERRO: PDF nao foi gerado. Verifique os logs.")
}
