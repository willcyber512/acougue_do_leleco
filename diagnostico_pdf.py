from pathlib import Path
import subprocess

out = []

def add(title):
    out.append("\n" + "=" * 60)
    out.append(title)
    out.append("=" * 60)

def run(cmd):
    try:
        result = subprocess.run(
            cmd,
            shell=True,
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
        )
        out.append(result.stdout)
    except Exception as e:
        out.append(f"ERRO AO RODAR {cmd}: {e}")

add("STATUS GIT")
run("git status --short")

add("BUSCA GERAL NO PROJETO")
run(r"""grep -R "Relatório Gerencial\|Formas de pagamento\|Distribuição do faturamento\|Controle do caixa\|Resumo do caixa\|CAIXA -\|_exportReportsPdf\|Configurar PDF" -n lib | head -500""")

path = Path("lib/screens/reports/reports_screen.dart")
text = path.read_text()
lines = text.splitlines()

patterns = [
    "class _PdfReportOptions",
    "Future<void> _showReportsPdfOptionsDialog",
    "var includeCashMovements",
    "includeCashMovements:",
    "title: const Text('Resumo do caixa')",
    "Future<void> _exportReportsPdf",
    "final paymentRows",
    "paymentRows.add",
    "cashSummaryProvider",
    "cashSummaryRows",
    "cashSummaryCategoryTableRows",
    "pw.Widget metricCard",
    "pw.Widget sectionTitle",
    "pw.Widget dataTable",
    "final widgets =",
    "widgets.addAll",
    "if (options.includePayments)",
    "if (options.includeCashMovements)",
    "if (options.includeProducts)",
    "Top produtos",
    "document.addPage",
    "pw.MultiPage",
]

add("MAPA DO reports_screen.dart")
for pattern in patterns:
    out.append(f"\n--- Procurando: {pattern} ---")
    found = False
    for i, line in enumerate(lines, start=1):
        if pattern in line:
            out.append(f"{i}: {line}")
            found = True
    if not found:
        out.append("NÃO ENCONTRADO")

def print_context(title, pattern, before=35, after=90):
    add(title)
    for idx, line in enumerate(lines):
        if pattern in line:
            start = max(0, idx - before)
            end = min(len(lines), idx + after + 1)
            for n in range(start, end):
                out.append(f"{n+1}: {lines[n]}")
            return
    out.append(f"NÃO ACHEI: {pattern}")

print_context("OPÇÕES DO PDF", "class _PdfReportOptions", 5, 90)
print_context("DIÁLOGO CONFIGURAR PDF", "Future<void> _showReportsPdfOptionsDialog", 5, 260)
print_context("INÍCIO DO EXPORT PDF", "Future<void> _exportReportsPdf", 5, 220)
print_context("HELPERS DO PDF / metricCard", "pw.Widget metricCard", 30, 160)
print_context("BLOCO REAL DE WIDGETS", "final widgets =", 30, 340)
print_context("BLOCO FORMAS DE PAGAMENTO", "if (options.includePayments)", 40, 180)

Path("diagnostico_pdf_relatorios.txt").write_text("\n".join(out))
print("Arquivo criado: diagnostico_pdf_relatorios.txt")
