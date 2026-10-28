<?php
declare(strict_types=1);
require __DIR__ . '/../../app/layout.php';

// ---- Alterações (sempre por POST, com token CSRF) ----------------------------
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_verificar();
    $acao = campo('acao');
    try {
        if ($acao === 'salvar') {
            $gid      = campo('gid');
            $nome     = campo('nome');
            $dominio  = strtolower(campo('dominio'));
            $original = campo('gid_original');      // vazio = cadastro novo

            if (!ctype_digit($gid) || $nome === '' || $dominio === '') {
                avisar('erro', 'Preencha GID (número), nome e domínio.');
                redirecionar('grupos.php' . ($original !== '' ? '?editar=' . urlencode($original) : ''));
            }
            if ($original === '') {
                executar('INSERT INTO grupo (gid, nome, dominio) VALUES (?, ?, ?)', [(int)$gid, $nome, $dominio]);
                avisar('ok', "Grupo $gid cadastrado.");
            } else {
                // Trocar o GID também atualiza alunos e hosts (ON UPDATE CASCADE).
                $n = executar('UPDATE grupo SET gid = ?, nome = ?, dominio = ? WHERE gid = ?',
                              [(int)$gid, $nome, $dominio, (int)$original]);
                avisar('ok', $n ? "Grupo $gid atualizado." : 'Nenhuma alteração feita.');
            }
        } elseif ($acao === 'remover') {
            $gid = (int)campo('gid');
            // Remove o grupo e, pela chave estrangeira (ON DELETE CASCADE), seus alunos e hosts.
            $n = executar('DELETE FROM grupo WHERE gid = ?', [$gid]);
            avisar($n ? 'ok' : 'erro', $n ? "Grupo $gid removido, com seus alunos e hosts." : "Grupo $gid não encontrado.");
        }
    } catch (PDOException $e) {
        avisar('erro', mensagem_erro_bd($e));
    }
    redirecionar('grupos.php');
}

// ---- Leitura ------------------------------------------------------------------
$edicao = null;
if (isset($_GET['editar'])) {
    $edicao = consultar_um('SELECT gid, nome, dominio FROM grupo WHERE gid = ?', [(int)$_GET['editar']]);
}
$grupos = consultar('SELECT g.gid, g.nome, g.dominio,
                            (SELECT COUNT(*) FROM aluno a WHERE a.gid = g.gid) AS alunos,
                            (SELECT COUNT(*) FROM host  h WHERE h.gid = g.gid) AS hosts
                       FROM grupo g ORDER BY g.gid');

cabecalho('Grupos', '../');
?>
<form method="post" class="formulario">
  <?= csrf_campo() ?>
  <input type="hidden" name="acao" value="salvar">
  <input type="hidden" name="gid_original" value="<?= h($edicao['gid'] ?? '') ?>">
  <h2><?= $edicao ? 'Editar grupo ' . h($edicao['gid']) : 'Novo grupo' ?></h2>
  <label>GID (número do grupo) <input name="gid" type="number" min="0" required value="<?= h($edicao['gid'] ?? '') ?>"></label>
  <label>Nome <input name="nome" required maxlength="100" value="<?= h($edicao['nome'] ?? '') ?>" placeholder="Grupo 1"></label>
  <label>Domínio <input name="dominio" required maxlength="255" value="<?= h($edicao['dominio'] ?? '') ?>" placeholder="grupo1.bsi-26-2.maceio.lab"></label>
  <div class="acoes">
    <button type="submit">Salvar</button>
    <?php if ($edicao): ?><a href="grupos.php">Cancelar</a><?php endif; ?>
  </div>
</form>

<table>
  <thead><tr><th>GID</th><th>Nome</th><th>Domínio</th><th>Alunos</th><th>Hosts</th><th></th></tr></thead>
  <tbody>
  <?php foreach ($grupos as $g): ?>
    <tr>
      <td><?= h($g['gid']) ?></td><td><?= h($g['nome']) ?></td><td><code><?= h($g['dominio']) ?></code></td>
      <td><?= h($g['alunos']) ?></td><td><?= h($g['hosts']) ?></td>
      <td class="botoes">
        <a href="grupos.php?editar=<?= h($g['gid']) ?>">Editar</a>
        <form method="post" onsubmit="return confirm('Remover o grupo <?= h($g['gid']) ?> com todos os seus alunos e hosts?');">
          <?= csrf_campo() ?><input type="hidden" name="acao" value="remover"><input type="hidden" name="gid" value="<?= h($g['gid']) ?>">
          <button type="submit" class="perigo">Remover</button>
        </form>
      </td>
    </tr>
  <?php endforeach; ?>
  <?php if (!$grupos): ?><tr><td colspan="6" class="vazio">Nenhum grupo cadastrado.</td></tr><?php endif; ?>
  </tbody>
</table>
<?php rodape();
