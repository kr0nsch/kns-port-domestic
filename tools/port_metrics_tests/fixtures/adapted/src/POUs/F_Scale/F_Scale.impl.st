F_Scale := rIn * rK;
IF rK = 0.0 THEN
    F_Scale := 0.0;
END_IF
// PORT: [build] ограничение вынесено в вызывающий код (docs/BUILD_ERRORS.md, запись 1)
