<?php
declare(strict_types=1);
require __DIR__ . '/../../app/layout.php';

cabecalho('Administrar', '../');
?>
<p>Você entrou como <strong><?= h(usuario_ldap() ?? 'desconhecido') ?></strong>. O Apache confirmou usuário, senha e grupo
no servidor <strong>LDAP</strong> antes de abrir esta página; o PHP não guarda nenhuma senha.</p>
<ul class="menu">
  <li><a href="grupos.php">Grupos</a> — número, nome e domínio de cada grupo.</li>
  <li><a href="alunos.php">Integrantes</a> — nome, login e e-mail, ligados a um grupo.</li>
  <li><a href="hosts.php">Máquinas virtuais</a> — nome, FQDN, IP e serviço de cada VM.</li>
</ul>
<?php rodape();
