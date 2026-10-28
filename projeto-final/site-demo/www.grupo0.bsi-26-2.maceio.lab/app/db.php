<?php
declare(strict_types=1);

/** Configuração do site (app/config.php). */
function config(): array
{
    static $cfg = null;
    if ($cfg === null) {
        $arquivo = __DIR__ . '/config.php';
        if (!is_file($arquivo)) {
            throw new RuntimeException('Arquivo app/config.php não encontrado. Copie app/config.exemplo.php para app/config.php.');
        }
        $cfg = require $arquivo;
    }
    return $cfg;
}

/**
 * Conexão única com o MariaDB da VM bd.
 * - ERRMODE_EXCEPTION: qualquer erro de SQL vira exceção (nada falha em silêncio).
 * - EMULATE_PREPARES=false: os parâmetros vão separados do SQL (proteção contra SQL injection).
 */
function conectar(): PDO
{
    static $pdo = null;
    if ($pdo === null) {
        $c = config();
        $dsn = sprintf('mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4', $c['host'], $c['porta'] ?? 3306, $c['banco']);
        $pdo = new PDO($dsn, $c['usuario'], $c['senha'], [
            PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES   => false,
            PDO::ATTR_TIMEOUT            => 5,
        ]);
    }
    return $pdo;
}

/** Executa um SELECT com parâmetros e devolve todas as linhas. */
function consultar(string $sql, array $parametros = []): array
{
    $stmt = conectar()->prepare($sql);
    $stmt->execute($parametros);
    return $stmt->fetchAll();
}

/** Executa um SELECT e devolve só a primeira linha (ou null). */
function consultar_um(string $sql, array $parametros = []): ?array
{
    $linhas = consultar($sql, $parametros);
    return $linhas[0] ?? null;
}

/** Executa INSERT, UPDATE ou DELETE e devolve o número de linhas afetadas. */
function executar(string $sql, array $parametros = []): int
{
    $stmt = conectar()->prepare($sql);
    $stmt->execute($parametros);
    return $stmt->rowCount();
}

/** Traduz os erros mais comuns do MariaDB para mensagens legíveis. */
function mensagem_erro_bd(PDOException $e): string
{
    $codigo = (int)($e->errorInfo[1] ?? 0);
    return match ($codigo) {
        1062    => 'Já existe um registro com esse valor (campo único repetido).',
        1451    => 'O registro está em uso por outra tabela e não pode ser alterado assim.',
        1452    => 'O grupo informado não existe.',
        default => 'Erro no banco de dados: ' . $e->getMessage(),
    };
}
