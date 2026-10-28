<?php
declare(strict_types=1);
require __DIR__ . '/../../app/layout.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_verificar();
    $acao = campo('acao');
    try {
        if ($acao === 'salvar') {
            $uid   = campo('uid');                 // vazio = cadastro novo
            $nome  = campo('nome');
            $login = strtolower(campo('login'));
            $email = strtolower(campo('email'));
            $gid   = campo('gid');

            $erros = [];
            if ($nome === '') $erros[] = 'nome';
            if (!preg_match('/^[a-z][a-z0-9._-]{1,63}$/', $login)) $erros[] = 'login (minúsculas, sem acento, ex.: fulano.tal)';
            if (!filter_var($email, FILTER_VALIDATE_EMAIL)) $erros[] = 'e-mail';
            if (!ctype_digit($gid)) $erros[] = 'grupo';
            if ($erros) {
                avisar('erro', 'Verifique: ' . implode(', ', $erros) . '.');
                redirecionar('alunos.php' . ($uid !== '' ? '?editar=' . urlencode($uid) : ''));
            }

            if ($uid === '') {
                executar('INSERT INTO aluno (nome, login, email, gid) VALUES (?, ?, ?, ?)', [$nome, $login, $email, (int)$gid]);
                avisar('ok', "Integrante $login cadastrado.");
            } else {
                $n = executar('UPDATE aluno SET nome = ?, login = ?, email = ?, gid = ? WHERE uid = ?',
                              [$nome, $login, $email, (int)$gid, (int)$uid]);
                avisar('ok', $n ? "Integrante $login atualizado." : 'Nenhuma alteração feita.');
            }
        } elseif ($acao === 'remover') {
            $n = executar('DELETE FROM aluno WHERE uid = ?', [(int)campo('uid')]);
            avisar($n ? 'ok' : 'erro', $n ? 'Integrante removido.' : 'Integrante não encontrado.');
        }
    } catch (PDOException $e) {
        avisar('erro', mensagem_erro_bd($e));
    }
    redirecionar('alunos.php');
}

$edicao = isset($_GET['editar'])
    ? consultar_um('SELECT uid, nome, login, email, gid FROM aluno WHERE uid = ?', [(int)$_GET['editar']])
    : null;
$alunos = consultar('SELECT a.uid, a.nome, a.login, a.email, a.gid, g.nome AS grupo
                       FROM aluno a JOIN grupo g ON g.gid = a.gid
                      ORDER BY a.gid, a.nome');

cabecalho('Integrantes', '../');
?>
<form method="post" class="formulario">
  <?= csrf_campo() ?>
  <input type="hidden" name="acao" value="salvar">
  <input type="hidden" name="uid" value="<?= h($edicao['uid'] ?? '') ?>">
  <h2><?= $edicao ? 'Editar integrante ' . h($edicao['login']) : 'Novo integrante' ?></h2>
  <label>Nome completo <input name="nome" required maxlength="255" value="<?= h($edicao['nome'] ?? '') ?>" placeholder="Fulano de Tal"></label>
  <label>Login (o mesmo do LDAP) <input name="login" required maxlength="64" value="<?= h($edicao['login'] ?? '') ?>" placeholder="fulano.tal"></label>
  <label>E-mail <input name="email" type="email" required maxlength="255" value="<?= h($edicao['email'] ?? '') ?>" placeholder="fulano.tal@grupo1.bsi-26-2.maceio.lab"></label>
  <label>Grupo <select name="gid" required><?= opcoes_grupos(isset($edicao['gid']) ? (int)$edicao['gid'] : null) ?></select></label>
  <div class="acoes">
    <button type="submit">Salvar</button>
    <?php if ($edicao): ?><a href="alunos.php">Cancelar</a><?php endif; ?>
  </div>
</form>

<table>
  <thead><tr><th>UID</th><th>Nome</th><th>Login</th><th>E-mail</th><th>Grupo</th><th></th></tr></thead>
  <tbody>
  <?php foreach ($alunos as $a): ?>
    <tr>
      <td><?= h($a['uid']) ?></td><td><?= h($a['nome']) ?></td><td><code><?= h($a['login']) ?></code></td>
      <td><?= h($a['email']) ?></td><td><?= h($a['gid'] . ' — ' . $a['grupo']) ?></td>
      <td class="botoes">
        <a href="alunos.php?editar=<?= h($a['uid']) ?>">Editar</a>
        <form method="post" onsubmit="return confirm('Remover <?= h($a['login']) ?>?');">
          <?= csrf_campo() ?><input type="hidden" name="acao" value="remover"><input type="hidden" name="uid" value="<?= h($a['uid']) ?>">
          <button type="submit" class="perigo">Remover</button>
        </form>
      </td>
    </tr>
  <?php endforeach; ?>
  <?php if (!$alunos): ?><tr><td colspan="6" class="vazio">Nenhum integrante cadastrado.</td></tr><?php endif; ?>
  </tbody>
</table>
<?php rodape();
