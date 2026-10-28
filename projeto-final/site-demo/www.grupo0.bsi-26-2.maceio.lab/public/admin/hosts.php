<?php
declare(strict_types=1);
require __DIR__ . '/../../app/layout.php';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    csrf_verificar();
    $acao = campo('acao');
    try {
        if ($acao === 'salvar') {
            $hid     = campo('hid');               // vazio = cadastro novo
            $nome    = strtolower(campo('nome'));
            $fqdn    = strtolower(rtrim(campo('fqdn'), '.'));
            $ip      = campo('ip');
            $servico = campo('servico');
            $gid     = campo('gid');

            $erros = [];
            if (!preg_match('/^[a-z0-9]([a-z0-9-]{0,62})$/', $nome)) $erros[] = 'nome (letras, números e hífen)';
            if (!preg_match('/^([a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z0-9-]{2,63}$/', $fqdn)) $erros[] = 'FQDN';
            if (!filter_var($ip, FILTER_VALIDATE_IP)) $erros[] = 'IP';
            if (!ctype_digit($gid)) $erros[] = 'grupo';
            if ($erros) {
                avisar('erro', 'Verifique: ' . implode(', ', $erros) . '.');
                redirecionar('hosts.php' . ($hid !== '' ? '?editar=' . urlencode($hid) : ''));
            }

            if ($hid === '') {
                executar('INSERT INTO host (nome, fqdn, ip, servico, gid) VALUES (?, ?, ?, ?, ?)',
                         [$nome, $fqdn, $ip, $servico, (int)$gid]);
                avisar('ok', "Host $fqdn cadastrado.");
            } else {
                $n = executar('UPDATE host SET nome = ?, fqdn = ?, ip = ?, servico = ?, gid = ? WHERE hid = ?',
                              [$nome, $fqdn, $ip, $servico, (int)$gid, (int)$hid]);
                avisar('ok', $n ? "Host $fqdn atualizado." : 'Nenhuma alteração feita.');
            }
        } elseif ($acao === 'remover') {
            $n = executar('DELETE FROM host WHERE hid = ?', [(int)campo('hid')]);
            avisar($n ? 'ok' : 'erro', $n ? 'Host removido.' : 'Host não encontrado.');
        }
    } catch (PDOException $e) {
        avisar('erro', mensagem_erro_bd($e));
    }
    redirecionar('hosts.php');
}

$edicao = isset($_GET['editar'])
    ? consultar_um('SELECT hid, nome, fqdn, ip, servico, gid FROM host WHERE hid = ?', [(int)$_GET['editar']])
    : null;
$hosts = consultar('SELECT h.hid, h.nome, h.fqdn, h.ip, h.servico, h.gid, g.nome AS grupo
                      FROM host h JOIN grupo g ON g.gid = h.gid
                     ORDER BY h.gid, INET_ATON(h.ip), h.nome');

cabecalho('Máquinas virtuais', '../');
?>
<form method="post" class="formulario">
  <?= csrf_campo() ?>
  <input type="hidden" name="acao" value="salvar">
  <input type="hidden" name="hid" value="<?= h($edicao['hid'] ?? '') ?>">
  <h2><?= $edicao ? 'Editar ' . h($edicao['fqdn']) : 'Nova máquina virtual' ?></h2>
  <label>Nome (hostname curto) <input name="nome" required maxlength="64" value="<?= h($edicao['nome'] ?? '') ?>" placeholder="www"></label>
  <label>FQDN <input name="fqdn" required maxlength="255" value="<?= h($edicao['fqdn'] ?? '') ?>" placeholder="www.grupo1.bsi-26-2.maceio.lab"></label>
  <label>IP <input name="ip" required maxlength="45" value="<?= h($edicao['ip'] ?? '') ?>" placeholder="10.10.101.20"></label>
  <label>Serviço <input name="servico" maxlength="100" value="<?= h($edicao['servico'] ?? '') ?>" placeholder="Apache + PHP"></label>
  <label>Grupo <select name="gid" required><?= opcoes_grupos(isset($edicao['gid']) ? (int)$edicao['gid'] : null) ?></select></label>
  <div class="acoes">
    <button type="submit">Salvar</button>
    <?php if ($edicao): ?><a href="hosts.php">Cancelar</a><?php endif; ?>
  </div>
</form>

<table>
  <thead><tr><th>HID</th><th>Nome</th><th>FQDN</th><th>IP</th><th>Serviço</th><th>Grupo</th><th></th></tr></thead>
  <tbody>
  <?php foreach ($hosts as $hst): ?>
    <tr>
      <td><?= h($hst['hid']) ?></td><td><?= h($hst['nome']) ?></td><td><code><?= h($hst['fqdn']) ?></code></td>
      <td><code><?= h($hst['ip']) ?></code></td><td><?= h($hst['servico']) ?></td><td><?= h($hst['gid'] . ' — ' . $hst['grupo']) ?></td>
      <td class="botoes">
        <a href="hosts.php?editar=<?= h($hst['hid']) ?>">Editar</a>
        <form method="post" onsubmit="return confirm('Remover <?= h($hst['fqdn']) ?>?');">
          <?= csrf_campo() ?><input type="hidden" name="acao" value="remover"><input type="hidden" name="hid" value="<?= h($hst['hid']) ?>">
          <button type="submit" class="perigo">Remover</button>
        </form>
      </td>
    </tr>
  <?php endforeach; ?>
  <?php if (!$hosts): ?><tr><td colspan="7" class="vazio">Nenhuma máquina cadastrada.</td></tr><?php endif; ?>
  </tbody>
</table>
<?php rodape();
