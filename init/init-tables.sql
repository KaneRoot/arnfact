USE arnfact;

CREATE TABLE IF NOT EXISTS user (
    userid varchar(50) NOT NULL
    , firstname varchar(50) NOT NULL
    , secondname varchar(50) NOT NULL
    , pseudo varchar(50) NOT NULL
    , town varchar(50) NOT NULL
    , postalcode varchar(10) NOT NULL
    , address varchar(1000) NOT NULL
    , passwd varchar(100) DEFAULT NULL
    , email varchar(100) DEFAULT NULL
    , admin tinyint(1) DEFAULT 0
    , PRIMARY KEY (userid)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS contractentry (
    contractentryid varchar(100) NOT NULL
    , startdate varchar(10) NOT NULL    -- yes, varchar, fuck it
    , duration varchar(15) NOT NULL     -- yes, varchar, fuck it
    , nb varchar(5) NOT NULL            -- yes, varchar, fuck it
    , PRIMARY KEY (contractentryid)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS contract (
    contractid varchar(100) NOT NULL
    , userid varchar(50) NOT NULL
    , contracttype varchar(10) NOT NULL
    , payment varchar(20) NOT NULL
    , lastpaymentdate varchar(10) NOT NULL
    , emissiondate varchar(10) NOT NULL
    , setupdate varchar(10) NOT NULL   -- yes, varchar, fuck it
    , PRIMARY KEY (contractid)
    -- , FOREIGN KEY (userid)
) ENGINE=InnoDB;

-- TODO

CREATE TABLE IF NOT EXISTS contract_assoc (
    contractid varchar(100) NOT NULL
    , contractentryid varchar(100) NOT NULL
    , PRIMARY KEY (contractid, contractentryid)
) ENGINE=InnoDB;
