<?php
declare(strict_types=1);
require __DIR__ . '/../app/layout.php';

$erro = null;
$totais = ['grupos' => 0, 'alunos' => 0, 'hosts' => 0];
$versao = '';
try {
    $totais = consultar_um('SELECT (SELECT COUNT(*) FROM grupo) AS grupos,
                                   (SELECT COUNT(*) FROM aluno) AS alunos,
                                   (SELECT COUNT(*) FROM host)  AS hosts');
    $versao = (string)conectar()->query('SELECT VERSION()')->fetchColumn();
} catch (Throwable $e) {
    $erro = $e->getMessage();
}

cabecalho('Projeto Final de LSOR');
?>
<p>Este site demonstra um servidor web <strong>LAMP</strong> distribuído em duas máquinas da rede do grupo:
o <strong>Apache com PHP</strong> roda na VM <code>www</code> e o <strong>MariaDB</strong> roda na VM <code>bd</code>.
Cada consulta abaixo atravessa a rede do grupo até o banco de dados.</p>

<?php if ($erro): ?>
  <p class="aviso erro">Sem conexão com o banco de dados em <code><?= h(config()['host']) ?></code>: <?= h($erro) ?></p>
  <p>Verifique o DNS, o <code>bind-address</code> do MariaDB, o usuário <code>siteapp</code> e o firewall.</p>
<?php else: ?>
  <p class="aviso ok">Conectado ao MariaDB <?= h($versao) ?> em <code><?= h(config()['host']) ?></code>.</p>
  <div class="cartoes">
    <div class="cartao"><span><?= h($totais['grupos']) ?></span>grupos</div>
    <div class="cartao"><span><?= h($totais['alunos']) ?></span>alunos</div>
    <div class="cartao"><span><?= h($totais['hosts']) ?></span>hosts</div>
  </div>
<?php endif; ?>

<h2>O que dá para fazer</h2>
<ul>
  <li><a href="consulta.php">Consultar</a> grupos, integrantes e máquinas virtuais (acesso livre).</li>
  <li><a href="admin/index.php">Administrar</a> os cadastros (cadastrar, editar e remover). Essa área pede usuário e senha do <strong>LDAP</strong> do grupo.</li>
</ul>
<?php rodape();
