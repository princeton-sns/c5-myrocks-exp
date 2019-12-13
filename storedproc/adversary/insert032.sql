use fdr;
drop procedure if exists insert032;

delimiter |

  CREATE PROCEDURE insert032(in_hot_k INT, in_hot_v INT,
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
                             in_k16 INT, in_kk16 INT, in_v16 INT,
                             in_k17 INT, in_kk17 INT, in_v17 INT,
                             in_k18 INT, in_kk18 INT, in_v18 INT,
                             in_k19 INT, in_kk19 INT, in_v19 INT,
                             in_k20 INT, in_kk20 INT, in_v20 INT,
                             in_k21 INT, in_kk21 INT, in_v21 INT,
                             in_k22 INT, in_kk22 INT, in_v22 INT,
                             in_k23 INT, in_kk23 INT, in_v23 INT,
                             in_k24 INT, in_kk24 INT, in_v24 INT,
                             in_k25 INT, in_kk25 INT, in_v25 INT,
                             in_k26 INT, in_kk26 INT, in_v26 INT,
                             in_k27 INT, in_kk27 INT, in_v27 INT,
                             in_k28 INT, in_kk28 INT, in_v28 INT,
                             in_k29 INT, in_kk29 INT, in_v29 INT,
                             in_k30 INT, in_kk30 INT, in_v30 INT,
                             in_k31 INT, in_kk31 INT, in_v31 INT,
                             in_k32 INT, in_kk32 INT, in_v32 INT
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
           (in_k16, in_kk16, in_v16),
           (in_k17, in_kk17, in_v17),
           (in_k18, in_kk18, in_v18),
           (in_k19, in_kk19, in_v19),
           (in_k20, in_kk20, in_v20),
           (in_k21, in_kk21, in_v21),
           (in_k22, in_kk22, in_v22),
           (in_k23, in_kk23, in_v23),
           (in_k24, in_kk24, in_v24),
           (in_k25, in_kk25, in_v25),
           (in_k26, in_kk26, in_v26),
           (in_k27, in_kk27, in_v27),
           (in_k28, in_kk28, in_v28),
           (in_k29, in_kk29, in_v29),
           (in_k30, in_kk30, in_v30),
           (in_k31, in_kk31, in_v31),
           (in_k32, in_kk32, in_v32);

    UPDATE HOTKEY
       SET V = in_hot_v
     WHERE K = in_hot_k;

	  COMMIT;

  END|

    delimiter ;
