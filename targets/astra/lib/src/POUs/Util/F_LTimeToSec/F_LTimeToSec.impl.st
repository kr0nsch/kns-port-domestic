// PORT: [types] проверить в Astra.IDE — литералы и преобразования LTIME (C11)
F_LTimeToSec := ULINT_TO_LREAL(LTIME_TO_ULINT(ltIn)) / GVL_Const.NS_PER_S;
