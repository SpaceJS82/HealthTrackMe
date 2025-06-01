DROP SCHEMA IF EXISTS yoaBaza;
CREATE SCHEMA yoaBaza DEFAULT CHARACTER SET utf8;
use yoaBaza

-- Onemogočanje preverjanj za varno brisanje in ponovno ustvarjanje
SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

CREATE SCHEMA IF NOT EXISTS `yoaBaza` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `yoaBaza`;

-- Tabela: user
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `iduser` INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(45) NOT NULL,
  `username` VARCHAR(45) NOT NULL UNIQUE,
  `password` VARCHAR(100) NOT NULL,
  `date_joined` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`iduser`)
) ENGINE=InnoDB;

-- Tabela: event
DROP TABLE IF EXISTS `event`;
CREATE TABLE `event` (
  `idevent` INT NOT NULL AUTO_INCREMENT,
  `user_iduser` INT NOT NULL,
  `metadata` VARCHAR(255) NOT NULL,
  `date` DATETIME NOT NULL,
  `type` ENUM('unknown', 'workout', 'journal_stats', 'health_achievement') NOT NULL,
  PRIMARY KEY (`idevent`),
  INDEX `idx_event_user` (`user_iduser`),
  CONSTRAINT `fk_event_user`
    FOREIGN KEY (`user_iduser`) REFERENCES `user` (`iduser`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Tabela: friendship
DROP TABLE IF EXISTS `friendship`;
CREATE TABLE `friendship` (
  `idfriendship` INT NOT NULL AUTO_INCREMENT,
  `user_iduser` INT NOT NULL,
  `friend_iduser` INT NOT NULL,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`idfriendship`),
  INDEX `idx_friendship_user` (`user_iduser`),
  INDEX `idx_friendship_friend` (`friend_iduser`),
  CONSTRAINT `fk_friendship_user`
    FOREIGN KEY (`user_iduser`) REFERENCES `user` (`iduser`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_friendship_friend`
    FOREIGN KEY (`friend_iduser`) REFERENCES `user` (`iduser`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Tabela: health_metric
DROP TABLE IF EXISTS `health_metric`;
CREATE TABLE `health_metric` (
  `idmetric` INT NOT NULL AUTO_INCREMENT,
  `date` DATETIME NOT NULL,
  `value` DOUBLE NOT NULL,
  `type` ENUM('sleep', 'fitness', 'stress') NOT NULL,
  `user_iduser` INT NOT NULL,
  PRIMARY KEY (`idmetric`),
  INDEX `idx_metric_user` (`user_iduser`),
  CONSTRAINT `fk_metric_user`
    FOREIGN KEY (`user_iduser`) REFERENCES `user` (`iduser`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Tabela: event_reaction
CREATE TABLE event_reaction (
idreaction INT NOT NULL AUTO_INCREMENT,
reaction VARCHAR(45) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
event_idevent INT NOT NULL,
user_iduser INT NOT NULL,
`created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
PRIMARY KEY (idreaction),
INDEX idx_reaction_event (event_idevent),
INDEX idx_reaction_user (user_iduser),
CONSTRAINT fk_reaction_event
FOREIGN KEY (event_idevent) REFERENCES event (idevent)
ON DELETE CASCADE ON UPDATE CASCADE,
CONSTRAINT fk_reaction_user
FOREIGN KEY (user_iduser) REFERENCES user (iduser)
ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci;

-- Tabela: friend_invite
DROP TABLE IF EXISTS `friend_invite`;
CREATE TABLE `friend_invite` (
  `idinvite` INT NOT NULL AUTO_INCREMENT,
  `date` DATETIME NOT NULL,
  `sender_iduser` INT NOT NULL,
  `receiver_iduser` INT NOT NULL,
  PRIMARY KEY (`idinvite`),
  INDEX `idx_invite_sender` (`sender_iduser`),
  INDEX `idx_invite_receiver` (`receiver_iduser`),
  CONSTRAINT `fk_invite_sender`
    FOREIGN KEY (`sender_iduser`) REFERENCES `user` (`iduser`)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_invite_receiver`
    FOREIGN KEY (`receiver_iduser`) REFERENCES `user` (`iduser`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Tabela: device token za push notifications
CREATE TABLE IF NOT EXISTS `device_token` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `user_iduser` INT NOT NULL,
  `token` VARCHAR(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_user_token` (`user_iduser`, `token`),
  CONSTRAINT `fk_device_user`
    FOREIGN KEY (`user_iduser`) REFERENCES `user` (`iduser`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tabela: inapp_events
DROP TABLE IF EXISTS `inapp_events`;
CREATE TABLE `inapp_events` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `title` VARCHAR(255) NOT NULL,
  `metadata` JSON NOT NULL,
  `date_created` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci;

-- Tabela: isAdmin
DROP TABLE IF EXISTS `isAdmin`;
CREATE TABLE `isAdmin` (
  `user_iduser` INT NOT NULL,
  PRIMARY KEY (`user_iduser`),
  CONSTRAINT `fk_isAdmin_user`
    FOREIGN KEY (`user_iduser`) REFERENCES `user` (`iduser`)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB
DEFAULT CHARSET=utf8mb4
COLLATE=utf8mb4_unicode_ci;

-- Povrnitev prvotnih nastavitev
SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
