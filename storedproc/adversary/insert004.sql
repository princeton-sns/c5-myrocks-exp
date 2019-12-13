use fdr;
drop procedure if exists insert004;

delimiter |

  CREATE PROCEDURE insert004(in_hot_k INT, in_hot_v INT,
                             in_k1 INT, in_kk1 INT, in_v1 INT,
                             in_k2 INT, in_kk2 INT, in_v2 INT,
                             in_k3 INT, in_kk3 INT, in_v3 INT,
                             in_k4 INT, in_kk4 INT, in_v4 INT
  )
  BEGIN

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
                           BEGIN
                             ROLLBACK;
                           END;

    START TRANSACTION;

    INSERT INTO KV (K1, K2, V)
    VALUES (in_k1, in_kk1, in_v1),
           (in_k2, in_kk2, in_v2),
           (in_k3, in_kk3, in_v3),
           (in_k4, in_kk4, in_v4);

    UPDATE HOTKEY
       SET V = in_hot_v
     WHERE K = in_hot_k;


	  COMMIT;

  END|

    delimiter ;
