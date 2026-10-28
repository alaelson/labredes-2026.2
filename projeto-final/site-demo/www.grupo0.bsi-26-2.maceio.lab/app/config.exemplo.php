<?php
// Copie este arquivo para config.php (na mesma pasta app/) e ajuste os valores.
// O config.php fica FORA da pasta public/: o Apache nunca o entrega ao navegador.
// Não versione o config.php com a senha real.
return [
    'grupo'   => 'Grupo 0',
    'dominio' => 'grupo0.bsi-26-2.maceio.lab',

    // Servidor de banco de dados (VM bd do grupo). Use o nome DNS do grupo.
    'host'    => 'bd.grupo0.bsi-26-2.maceio.lab',
    'porta'   => 3306,
    'banco'   => 'projeto',
    'usuario' => 'siteapp',
    'senha'   => 'TROQUE-ESTA-SENHA',
];
