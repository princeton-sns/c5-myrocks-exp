use fdr;
drop procedure if exists insert016;

delimiter |

  CREATE PROCEDURE insert016(in_hot_k INT, in_hot_v INT,
                             in_k1 INT, in_kk1 INT, in_v1 INT,
                             in_k2 INT, in_kk2 INT, in_v2 INT,
                             in_k3 INT, in_kk3 INT, in_v3 INT,
                             in_k4 INT, in_kk4 INT, in_v4 INT,
                             in_k5 INT, in_kk5 INT, in_v5 INT,
                             in_k6 INT, in_kk6 INT, in_v6 INT,
                             in_k7 INT, in_kk7 INT, in_v7 INT,
                             in_k8 INT, in_kk8 INT, in_v8 INT,
                             in_k9 INT, in_kk9 INT, in_v9 INT,
                             in_k10 INT, in_kk10 INT, in_v10 INT,
                             in_k11 INT, in_kk11 INT, in_v11 INT,
                             in_k12 INT, in_kk12 INT, in_v12 INT,
                             in_k13 INT, in_kk13 INT, in_v13 INT,
                             in_k14 INT, in_kk14 INT, in_v14 INT,
                             in_k15 INT, in_kk15 INT, in_v15 INT,
                             in_k16 INT, in_kk16 INT, in_v16 INT
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
           (in_k4, in_kk4, in_v4),
           (in_k5, in_kk5, in_v5),
           (in_k6, in_kk6, in_v6),
           (in_k7, in_kk7, in_v7),
           (in_k8, in_kk8, in_v8),
           (in_k9, in_kk9, in_v9),
           (in_k10, in_kk10, in_v10),
           (in_k11, in_kk11, in_v11),
           (in_k12, in_kk12, in_v12),
           (in_k13, in_kk13, in_v13),
           (in_k14, in_kk14, in_v14),
           (in_k15, in_kk15, in_v15),
           (in_k16, in_kk16, in_v16);

    UPDATE HOTKEY
       SET V = in_hot_v
     WHERE K = in_hot_k;

	  COMMIT;

  END|

    delimiter ;
