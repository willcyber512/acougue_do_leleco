#!/usr/bin/env bash
set -e

echo "======================================"
echo " CHECK FINAL - ACOUGUE DO LELECO"
echo "======================================"

echo ""
echo "1) Baixando dependencias..."
flutter pub get

echo ""
echo "2) Analisando codigo..."
flutter analyze

echo ""
echo "3) Testando parser de etiqueta..."
if [ -f tool/test_scale_barcode_parser.dart ]; then
  dart run tool/test_scale_barcode_parser.dart
else
  echo "Arquivo tool/test_scale_barcode_parser.dart nao encontrado. Pulando."
fi

echo ""
echo "4) Conferindo restos de integracao direta com balanca..."
grep -RIn "ScaleIntegrationScreen\|RamuzaTcpScaleService\|ScaleServiceFactory\|FakeScaleService\|scale_plu\|ramuza_debug_main" lib tool || true

echo ""
echo "======================================"
echo " CHECK FINAL CONCLUIDO"
echo "======================================"
