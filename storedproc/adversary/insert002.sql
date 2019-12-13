use fdr;
drop procedure if exists insert002;

delimiter |

  CREATE PROCEDURE insert002(in_hot_k INT, in_hot_v INT,
                             in_k1 INT, in_kk1 INT, in_v1 INT,
                             in_k2 INT, in_kk2 INT, in_v2 INT)
  BEGIN

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
                           BEGIN
                             ROLLBACK;
                           END;

    START TRANSACTION;

    INSERT INTO KV (K1, K2, V)
    VALUES (in_k1, in_kk1, in_v1),
           (in_k2, in_kk2, in_v2);

    UPDATE HOTKEY
       SET V = in_hot_v
     WHERE K = in_hot_k;

	  COMMIT;

  END|

    delimiter ;
