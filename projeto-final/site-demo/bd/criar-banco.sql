-- =====================================================================
-- Banco de dados do site demo do Projeto Final (LSOR - BSI 2026.2)
-- Executar na VM bd do grupo:   sudo mariadb < criar-banco.sql
--
-- Antes de executar, troque:
--   10.10.101.4  -> IP do servidor www do seu grupo
--   TROQUE-ESTA-SENHA -> uma senha forte (a mesma do app/config.php no www)
-- =====================================================================

-- O arquivo está em UTF-8: sem esta linha, os acentos ficam corrompidos no banco.
SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS projeto
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE projeto;

-- Grupos do projeto. O GID é o número do grupo (0, 1, 2, ...).
CREATE TABLE IF NOT EXISTS grupo (
  gid     INT UNSIGNED  NOT NULL,
  nome    VARCHAR(100)  NOT NULL,
  dominio VARCHAR(255)  NOT NULL,
  PRIMARY KEY (gid),
  UNIQUE KEY uk_grupo_dominio (dominio)
) ENGINE=InnoDB;

-- Integrantes. Remover ou renumerar um grupo propaga para cá (chave estrangeira).
CREATE TABLE IF NOT EXISTS aluno (
  uid   INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nome  VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  login VARCHAR(64)  NOT NULL,
  gid   INT UNSIGNED NOT NULL,
  PRIMARY KEY (uid),
  UNIQUE KEY uk_aluno_email (email),
  UNIQUE KEY uk_aluno_login (login),
  CONSTRAINT fk_aluno_grupo FOREIGN KEY (gid) REFERENCES grupo (gid)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- Máquinas virtuais do grupo.
CREATE TABLE IF NOT EXISTS host (
  hid     INT UNSIGNED NOT NULL AUTO_INCREMENT,
  nome    VARCHAR(64)  NOT NULL,
  fqdn    VARCHAR(255) NOT NULL,
  ip      VARCHAR(45)  NOT NULL,
  servico VARCHAR(100) NOT NULL DEFAULT '',
  gid     INT UNSIGNED NOT NULL,
  PRIMARY KEY (hid),
  UNIQUE KEY uk_host_fqdn (fqdn),
  CONSTRAINT fk_host_grupo FOREIGN KEY (gid) REFERENCES grupo (gid)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- Dados de exemplo do Grupo 0 (modelo). Substitua pelos dados do seu grupo.
INSERT IGNORE INTO grupo (gid, nome, dominio) VALUES
  (0, 'Grupo 0', 'grupo0.bsi-26-2.maceio.lab');

INSERT IGNORE INTO aluno (nome, email, login, gid) VALUES
  ('Fulano de Tal',      'fulano.tal@grupo0.bsi-26-2.maceio.lab',       'fulano.tal',       0),
  ('Fulustreca dos Grudes', 'fulustreca.grudes@grupo0.bsi-26-2.maceio.lab', 'fulustreca.grudes', 0),
  ('Beltrano da Silva',  'beltrano.silva@grupo0.bsi-26-2.maceio.lab',   'beltrano.silva',   0),
  ('Cicrano de Souza',   'cicrano.souza@grupo0.bsi-26-2.maceio.lab',    'cicrano.souza',    0);

INSERT IGNORE INTO host (nome, fqdn, ip, servico, gid) VALUES
  ('gw',       'gw.grupo0.bsi-26-2.maceio.lab',       '10.10.101.1', 'Gateway, NAT e firewall',    0),
  ('ns1',      'ns1.grupo0.bsi-26-2.maceio.lab',      '10.10.101.2', 'DNS primário (BIND9)',       0),
  ('ns2',      'ns2.grupo0.bsi-26-2.maceio.lab',      '10.10.101.3', 'DNS secundário (BIND9)',     0),
  ('www',      'www.grupo0.bsi-26-2.maceio.lab',      '10.10.101.4', 'Apache + PHP e SFTP',        0),
  ('bd',       'bd.grupo0.bsi-26-2.maceio.lab',       '10.10.101.5', 'MariaDB',                    0),
  ('arquivos', 'arquivos.grupo0.bsi-26-2.maceio.lab', '10.10.101.6', 'Samba e SFTP',               0),
  ('ldap',     'ldap.grupo0.bsi-26-2.maceio.lab',     '10.10.101.7', 'OpenLDAP (login unificado)', 0),
  ('mail',     'mail.grupo0.bsi-26-2.maceio.lab',     '10.10.101.8', 'Postfix e Dovecot',          0);

-- Usuário da aplicação: só entra a partir do servidor www e só no banco "projeto",
-- com as quatro operações de que o site precisa (nada de ALL PRIVILEGES).
CREATE USER IF NOT EXISTS 'siteapp'@'10.10.101.4' IDENTIFIED BY 'TROQUE-ESTA-SENHA';
GRANT SELECT, INSERT, UPDATE, DELETE ON projeto.* TO 'siteapp'@'10.10.101.4';

-- Conferência
SHOW TABLES;
SELECT g.gid, g.nome, COUNT(DISTINCT a.uid) AS alunos, COUNT(DISTINCT h.hid) AS hosts
  FROM grupo g LEFT JOIN aluno a ON a.gid = g.gid LEFT JOIN host h ON h.gid = g.gid
 GROUP BY g.gid, g.nome;
