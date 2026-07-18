from pathlib import Path
import subprocess

out = []

def add(title):
    out.append("\n" + "=" * 70)
    out.append(title)
    out.append("=" * 70)

def run(cmd):
    result = subprocess.run(
        cmd,
        shell=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
    )
    out.append(result.stdout)

def dump_file(file_path):
    path = Path(file_path)
    add(file_path)
    if not path.exists():
        out.append("ARQUIVO NÃO EXISTE")
        return

    lines = path.read_text().splitlines()
    for i, line in enumerate(lines, start=1):
        out.append(f"{i}: {line}")

add("STATUS GIT")
run("git status --short")

add("BUSCAS IMPORTANTES")
run(r"""grep -R "SupplierPurchase\|addPurchase\|updatePurchase\|deletePurchase\|paid\|Pago\|Em aberto\|paymentMethod\|CashMovementProvider\|addMovement\|CashMovementCategory" -n lib/screens/suppliers lib/providers lib/models lib/main.dart | head -500""")

dump_file("lib/models/supplier_purchase.dart")
dump_file("lib/providers/suppliers_provider.dart")
dump_file("lib/screens/suppliers/suppliers_screen.dart")
dump_file("lib/models/cash_movement.dart")
dump_file("lib/providers/cash_movement_provider.dart")
dump_file("lib/main.dart")

Path("diagnostico_fornecedores_caixa.txt").write_text("\n".join(out))
print("Arquivo criado: diagnostico_fornecedores_caixa.txt")
