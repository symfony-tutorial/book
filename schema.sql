
CREATE SCHEMA IF NOT EXISTS `symfony` DEFAULT CHARACTER SET 'utf8' COLLATE 'utf8_unicode_ci';

USE `symfony`;

/* Category */
CREATE TABLE IF NOT EXISTS `category` (
  `id` SMALLINT(5) UNSIGNED NOT NULL AUTO_INCREMENT,
  `parent_category_id` SMALLINT(5) UNSIGNED NULL DEFAULT NULL,
  `label` VARCHAR(45) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) ,
  INDEX `idx_parent_category_id` (`parent_category_id` ASC) ,
  CONSTRAINT `fk_category_parent_category_id`
    FOREIGN KEY (`parent_category_id`)
    REFERENCES `category` (`id`))
ENGINE = InnoDB;

/* Product */
CREATE TABLE IF NOT EXISTS `product` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(45) NOT NULL,
  `title` VARCHAR(200) NULL DEFAULT NULL,
  `description` LONGTEXT NULL DEFAULT NULL,
  PRIMARY KEY (`id`) ,
  INDEX `idx_code` (`code` ASC) )
ENGINE = InnoDB;

/* Category has Product */
CREATE TABLE IF NOT EXISTS `category_has_product` (
  `category_id` SMALLINT(5) UNSIGNED NOT NULL,
  `product_id` INT(11) UNSIGNED NOT NULL,
  PRIMARY KEY (`category_id`, `product_id`) ,
  INDEX `idx_categoy_id` (`category_id` ASC) ,
  INDEX `idx_product_id` (`product_id` ASC) ,
  CONSTRAINT `fk_category_has_product_category_id`
    FOREIGN KEY (`category_id`)
    REFERENCES `category` (`id`),
  CONSTRAINT `fk_category_has_product_product_id`
    FOREIGN KEY (`product_id`)
    REFERENCES `product` (`id`)
)
ENGINE = InnoDB;

/* Warehouse */
CREATE TABLE IF NOT EXISTS `warehouse` (
  `id` SMALLINT(5) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(45) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;

/* Product Stock */
CREATE TABLE IF NOT EXISTS `product_stock` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` INT(11) UNSIGNED NOT NULL,
  `warehouse_id` SMALLINT(5) UNSIGNED NOT NULL,
  `quantity` INT(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) ,
  INDEX `idx_product_id` (`product_id` ASC) ,
  INDEX `idx_warehouse_id` (`warehouse_id` ASC) ,
  CONSTRAINT `fk_product_stock_product_id`
    FOREIGN KEY (`product_id`)
    REFERENCES `product` (`id`),
  CONSTRAINT `fk_product_stock_warehouse_id`
    FOREIGN KEY (`warehouse_id`)
    REFERENCES `warehouse` (`id`))
ENGINE = InnoDB;

/* Country */
CREATE TABLE IF NOT EXISTS `country` (
  `id` SMALLINT(6) UNSIGNED NOT NULL AUTO_INCREMENT,
  `code` VARCHAR(5) NOT NULL,
  `name` VARCHAR(60) NOT NULL,
  `currency` VARCHAR(3) NOT NULL,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;

/* Address */
CREATE TABLE IF NOT EXISTS `address` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `country_id` SMALLINT(6) UNSIGNED NOT NULL,
  `name` VARCHAR(45) NULL DEFAULT NULL,
  `city` VARCHAR(45) NULL DEFAULT NULL,
  `street_name` VARCHAR(45) NULL DEFAULT NULL,
  `street_number` VARCHAR(45) NULL DEFAULT NULL,
  `building` VARCHAR(45) NULL DEFAULT NULL,
  `entrance` VARCHAR(45) NULL DEFAULT NULL,
  `number` VARCHAR(45) NULL DEFAULT NULL,
  `deleted` TINYINT(1) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) ,
  INDEX `idx_country_id` (`country_id` ASC) ,
  CONSTRAINT `fk_address_country_id`
    FOREIGN KEY (`country_id`)
    REFERENCES `country` (`id`))
ENGINE = InnoDB;

/* Customer */
CREATE TABLE IF NOT EXISTS `customer` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(45) NULL DEFAULT NULL,
  `email` VARCHAR(45) NULL DEFAULT NULL,
  `mobile_phone` VARCHAR(45) NULL DEFAULT NULL,
  `phone` VARCHAR(45) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;

/* Customer Has Address */
CREATE TABLE IF NOT EXISTS `customer_has_address` (
  `address_id` INT(11) UNSIGNED NOT NULL,
  `customer_id` INT(11) UNSIGNED NOT NULL,
  INDEX `idx_address_id` (`address_id` ASC) ,
  INDEX `idx_customer_id` (`customer_id` ASC) ,
  CONSTRAINT `fk_customer_has_address_address_id`
    FOREIGN KEY (`address_id`)
    REFERENCES `address` (`id`),
  CONSTRAINT `fk_customer_has_address_customer_id`
    FOREIGN KEY (`customer_id`)
    REFERENCES `customer` (`id`))
ENGINE = InnoDB;

/* Order */
CREATE TABLE IF NOT EXISTS `order` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `shipping_address_id` INT(11) UNSIGNED NULL DEFAULT NULL,
  `billing_address_id` INT(11) UNSIGNED NULL DEFAULT NULL,
  `status` TINYINT(4) NULL DEFAULT NULL,
  `create_date` DATETIME NULL DEFAULT NULL,
  `customer_id` INT(11) UNSIGNED NOT NULL,
  PRIMARY KEY (`id`, `customer_id`) ,
  INDEX `idx_shipping_address_id` (`shipping_address_id` ASC) ,
  INDEX `idx_billing_address_id` (`billing_address_id` ASC) ,
  INDEX `idx_status` (`status` ASC) ,
  INDEX `idx_customer_id` (`customer_id` ASC) ,
  CONSTRAINT `fk_order_shipping_address_id`
    FOREIGN KEY (`shipping_address_id`)
    REFERENCES `address` (`id`),
  CONSTRAINT `fk_order_billing_address_id`
    FOREIGN KEY (`billing_address_id`)
    REFERENCES `address` (`id`),
  CONSTRAINT `fk_order_customer_id`
    FOREIGN KEY (`customer_id`)
    REFERENCES `customer` (`id`))
ENGINE = InnoDB;

/* Product Sale */
CREATE TABLE IF NOT EXISTS `product_sale` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `product_id` INT(11) UNSIGNED NOT NULL,
  `active` TINYINT(1) NULL DEFAULT 0,
  `start_date` DATETIME NULL DEFAULT NULL,
  `end_date` DATETIME NULL DEFAULT NULL,
  `price` INT(11) NOT NULL,
  PRIMARY KEY (`id`) ,
  INDEX `idx_product_id` (`product_id` ASC) ,
  INDEX `idx_start_date` (`start_date` ASC) ,
  INDEX `idx_end_date` (`end_date` ASC) ,
  CONSTRAINT `fk_product_sale_product_id`
    FOREIGN KEY (`product_id`)
    REFERENCES `product` (`id`))
ENGINE = InnoDB;

/* Order Product Line*/
CREATE TABLE IF NOT EXISTS `order_product_line` (
  `id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` INT(11) UNSIGNED NOT NULL,
  `product_sale_id` INT(11) UNSIGNED NOT NULL,
  `quantity` INT(11) NULL DEFAULT NULL,
  PRIMARY KEY (`id`) ,
  INDEX `idx_order_id` (`order_id` ASC) ,
  INDEX `idx_product_sale_id` (`product_sale_id` ASC) ,
  CONSTRAINT `fk_order_product_line_order_id`
    FOREIGN KEY (`order_id`)
    REFERENCES `order` (`id`),
  CONSTRAINT `fk_order_product_line_product_sale_id`
    FOREIGN KEY (`product_sale_id`)
    REFERENCES `product_sale` (`id`))
ENGINE = InnoDB;






