#!/bin/bash
set -e

echo ">>> Iniciando SQL Server..."
/opt/mssql/bin/sqlservr &
SQL_PID=$!

echo ">>> Aguardando SQL Server ficar pronto..."
for i in {1..50}; do
  if /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$MSSQL_SA_PASSWORD" -C -No -Q "SELECT 1" > /dev/null 2>&1; then
    echo ">>> SQL Server pronto!"
    break
  fi
  echo "... tentativa $i/50"
  sleep 2
  if [ $i -eq 50 ]; then
    echo "Erro: SQL Server não respondeu."
    kill $SQL_PID 2>/dev/null || true
    exit 1
  fi
done

BAK_FILE="/var/opt/mssql/backup/AdventureWorks2022.bak"

# Verifica se o banco já existe
echo ">>> Verificando se banco AdventureWorks2022 já existe..."
DB_EXISTS=$(/opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$MSSQL_SA_PASSWORD" -C -No \
  -Q "SET NOCOUNT ON; SELECT name FROM sys.databases WHERE name = 'AdventureWorks2022'" \
  -h -1 2>/dev/null | xargs || echo "")

if [ -z "$DB_EXISTS" ] || [ "$DB_EXISTS" != "AdventureWorks2022" ]; then
  echo ">>> Banco não encontrado, iniciando processo de restore..."

  if [ ! -f "$BAK_FILE" ]; then
    echo ">>> Baixando AdventureWorks2022.bak (pode levar alguns minutos)..."
    if ! wget -q --show-progress \
      https://github.com/Microsoft/sql-server-samples/releases/download/adventureworks/AdventureWorks2022.bak \
      -O "$BAK_FILE" 2>&1; then
      echo "Erro ao baixar arquivo. Verifique sua conexão."
      kill $SQL_PID 2>/dev/null || true
      exit 1
    fi
    echo ">>> Download concluído!"
  else
    echo ">>> Arquivo .bak já existe, usando cache."
  fi

  echo ">>> Restaurando banco de dados..."
  if /opt/mssql-tools18/bin/sqlcmd -S localhost -U SA -P "$MSSQL_SA_PASSWORD" -C -No \
    -i /scripts/restore.sql; then
    echo ">>> Banco restaurado com sucesso!"
  else
    echo "Erro ao restaurar banco de dados."
    kill $SQL_PID 2>/dev/null || true
    exit 1
  fi
else
  echo ">>> AdventureWorks2022 já existe, pulando restore."
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║    SQL Server e banco de dados AdventureWorks2022 prontos!    ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

wait $SQL_PID