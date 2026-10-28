<?php
declare(strict_types=1);
require __DIR__ . '/../app/layout.php';

// Filtros vindos da URL (GET): grupo e texto de busca.
$gid   = (isset($_GET['gid']) && $_GET['gid'] !== '') ? (int)$_GET['gid'] : null;
$busca = trim((string)($_GET['q'] ?? ''));

$where  = [];
$params = [];
if ($gid !== null) {
    $where[] = 'g.gid = :gid';
    $params['gid'] = $gid;
}
$filtro = $where ? 'WHERE ' . implode(' AND ', $where) : '';

$erro = null;
try {
    $grupos = consultar("SELECT g.gid, g.nome, g.dominio,
                                (SELECT COUNT(*) FROM aluno a WHERE a.gid = g.gid) AS alunos,
                                (SELECT COUNT(*) FROM host  h WHERE h.gid = g.gid) AS hosts
                           FROM grupo g $filtro ORDER BY g.gid", $params);

    // Na busca, o mesmo texto procura em nome, login/FQDN e serviço.
    $pAluno = $params;
    $wAluno = $where;
    $pHost  = $params;
    $wHost  = $where;
    if ($busca !== '') {
        $wAluno[] = '(a.nome LIKE :b1 OR a.login LIKE :b2 OR a.email LIKE :b3)';
        $pAluno += ['b1' => "%$busca%", 'b2' => "%$busca%", 'b3' => "%$busca%"];
        $wHost[]  = '(h.nome LIKE :b1 OR h.fqdn LIKE :b2 OR h.servico LIKE :b3 OR h.ip LIKE :b4)';
        $pHost   += ['b1' => "%$busca%", 'b2' => "%$busca%", 'b3' => "%$busca%", 'b4' => "%$busca%"];
    }
    $alunos = consultar('SELECT a.uid, a.nome, a.login, a.email, g.gid, g.nome AS grupo
                           FROM aluno a JOIN grupo g ON g.gid = a.gid '
                        . ($wAluno ? 'WHERE ' . implode(' AND ', $wAluno) : '') .
                        ' ORDER BY g.gid, a.nome', $pAluno);
    $hosts  = consultar('SELECT h.hid, h.nome, h.fqdn, h.ip, h.servico, g.gid, g.nome AS grupo
                           FROM host h JOIN grupo g ON g.gid = h.gid '
                        . ($wHost ? 'WHERE ' . implode(' AND ', $wHost) : '') .
                        ' ORDER BY g.gid, INET_ATON(h.ip), h.nome', $pHost);
} catch (Throwable $e) {
    $erro = $e->getMessage();
    $grupos = $alunos = $hosts = [];
}

cabecalho('Consultar');
?>
<form method="get" class="filtros">
  <label>Grupo
    <select name="gid">
      <option value="">Todos</option>
      <?php if (!$erro) echo opcoes_grupos($gid); ?>
    </select>
  </label>
  <label>Buscar <input type="search" name="q" value="<?= h($busca) ?>" placeholder="nome, login, FQDN, IP ou serviço"></label>
  <button type="submit">Filtrar</button>
  <a href="consulta.php">Limpar</a>
</form>

<?php if ($erro): ?>
  <p class="aviso erro">Não foi possível consultar o banco: <?= h($erro) ?></p>
<?php endif; ?>

<h2>Grupos</h2>
<table>
  <thead><tr><th>GID</th><th>Nome</th><th>Domínio</th><th>Alunos</th><th>Hosts</th></tr></thead>
  <tbody>
  <?php foreach ($grupos as $g): ?>
    <tr><td><?= h($g['gid']) ?></td><td><?= h($g['nome']) ?></td><td><code><?= h($g['dominio']) ?></code></td>
        <td><?= h($g['alunos']) ?></td><td><?= h($g['hosts']) ?></td></tr>
  <?php endforeach; ?>
  <?php if (!$grupos): ?><tr><td colspan="5" class="vazio">Nenhum grupo encontrado.</td></tr><?php endif; ?>
  </tbody>
</table>

<h2>Integrantes</h2>
<table>
  <thead><tr><th>UID</th><th>Nome</th><th>Login</th><th>E-mail</th><th>Grupo</th></tr></thead>
  <tbody>
  <?php foreach ($alunos as $a): ?>
    <tr><td><?= h($a['uid']) ?></td><td><?= h($a['nome']) ?></td><td><code><?= h($a['login']) ?></code></td>
        <td><?= h($a['email']) ?></td><td><?= h($a['gid'] . ' — ' . $a['grupo']) ?></td></tr>
  <?php endforeach; ?>
  <?php if (!$alunos): ?><tr><td colspan="5" class="vazio">Nenhum integrante encontrado.</td></tr><?php endif; ?>
  </tbody>
</table>

<h2>Máquinas virtuais</h2>
<table>
  <thead><tr><th>HID</th><th>Nome</th><th>FQDN</th><th>IP</th><th>Serviço</th><th>Grupo</th></tr></thead>
  <tbody>
  <?php foreach ($hosts as $hst): ?>
    <tr><td><?= h($hst['hid']) ?></td><td><?= h($hst['nome']) ?></td><td><code><?= h($hst['fqdn']) ?></code></td>
        <td><code><?= h($hst['ip']) ?></code></td><td><?= h($hst['servico']) ?></td><td><?= h($hst['gid'] . ' — ' . $hst['grupo']) ?></td></tr>
  <?php endforeach; ?>
  <?php if (!$hosts): ?><tr><td colspan="6" class="vazio">Nenhuma máquina encontrada.</td></tr><?php endif; ?>
  </tbody>
</table>
<?php rodape();
