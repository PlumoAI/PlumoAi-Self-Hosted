-- User is created by MySQL from secrets (mysql_user, mysql_password).
-- This runs only on first container startup (fresh mysql_data volume).

-- Full access to all current & future prod_* databases
GRANT ALL PRIVILEGES ON `prod\_%`.* TO 'plumoai_user'@'%';
GRANT ALL PRIVILEGES ON `plumoai_prod_model` TO 'plumoai_user'@'%';

-- Allow runtime database creation (API / user-click DB creation)
GRANT CREATE ON *.* TO 'plumoai_user'@'%';

FLUSH PRIVILEGES;
