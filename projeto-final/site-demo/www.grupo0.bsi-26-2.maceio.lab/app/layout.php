<?php
declare(strict_types=1);

require_once __DIR__ . '/db.php';

if (session_status() !== PHP_SESSION_ACTIVE) {
    session_start();
}

/** Escapa texto antes de colocá-lo no HTML (evita XSS). */
function h(mixed $valor): string
{
    return htmlspecialchars((string)$valor, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
}

/** Usuário autenticado pelo Apache no LDAP (só existe dentro de /admin). */
function usuario_ldap(): ?string
{
    return $_SERVER['REMOTE_USER'] ?? $_SERVER['PHP_AUTH_USER'] ?? null;
}

/** Mensagem que sobrevive a um redirecionamento (padrão POST → redirect → GET). */
function avisar(string $tipo, string $texto): void
{
    $_SESSION['avisos'][] = ['tipo' => $tipo, 'texto' => $texto];
}

function redirecionar(string $url): never
{
    header('Location: ' . $url, true, 303);
    exit;
}

/** Token contra CSRF: todo formulário que altera dados precisa enviá-lo. */
function csrf_token(): string
{
    if (empty($_SESSION['csrf'])) {
        $_SESSION['csrf'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf'];
}

function csrf_campo(): string
{
    return '<input type="hidden" name="csrf" value="' . h(csrf_token()) . '">';
}

function csrf_verificar(): void
{
    if (!hash_equals(csrf_token(), (string)($_POST['csrf'] ?? ''))) {
        http_response_code(400);
        exit('Requisição inválida (token CSRF). Volte e recarregue a página.');
    }
}

/** Lê um campo de texto do POST, sem espaços nas pontas. */
function campo(string $nome): string
{
    return trim((string)($_POST[$nome] ?? ''));
}

function cabecalho(string $titulo, string $base = ''): void
{
    $c = config();
    $usuario = usuario_ldap();
    ?>
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title><?= h($titulo) ?> · <?= h($c['grupo']) ?></title>
<link rel="stylesheet" href="<?= h($base) ?>css/estilo.css">
</head>
<body>
<header class="topo">
  <div class="marca"><strong><?= h($c['grupo']) ?></strong><span><?= h($c['dominio']) ?></span></div>
  <nav>
    <a href="<?= h($base) ?>index.php">Início</a>
    <a href="<?= h($base) ?>consulta.php">Consultar</a>
    <a href="<?= h($base) ?>admin/index.php">Administrar</a>
  </nav>
  <?php if ($usuario): ?><div class="sessao">LDAP: <strong><?= h($usuario) ?></strong></div><?php endif; ?>
</header>
<main>
<h1><?= h($titulo) ?></h1>
<?php
    foreach ($_SESSION['avisos'] ?? [] as $a) {
        echo '<p class="aviso ' . h($a['tipo']) . '">' . h($a['texto']) . '</p>';
    }
    unset($_SESSION['avisos']);
}

function rodape(): void
{
    ?>
</main>
<footer>
  Servidor web: <code><?= h(gethostname()) ?></code> ·
  Banco de dados: <code><?= h(config()['host']) ?></code> ·
  LSOR — BSI 2026.2 — IFAL Campus Maceió
</footer>
</body>
</html>
<?php
}

/** Lista de grupos para os campos de seleção. */
function opcoes_grupos(?int $selecionado): string
{
    $html = '';
    foreach (consultar('SELECT gid, nome FROM grupo ORDER BY gid') as $g) {
        $sel = ($selecionado !== null && (int)$g['gid'] === $selecionado) ? ' selected' : '';
        $html .= '<option value="' . h($g['gid']) . '"' . $sel . '>' . h($g['gid'] . ' — ' . $g['nome']) . '</option>';
    }
    return $html;
}
