// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/**
 *  Original code written by:
 *  - Travis Moore, Jason Huan, Same Kazemian.
 * NOTE: Slide rulers on the blockchain
 * Good stuff here too https://forum.openzeppelin.com/t/list-of-solidity-libraries-in-the-wild/2250
 */

contract ArthBond_Curves_RC_Discharge {
    // The RC Charging Formula is a nice curve
    // http://hyperphysics.phy-astr.gsu.edu/hbase/electric/capchg.html#c2

    // 400000 + (1000000 - 400000) *(1 - (1 / (2.71828^(x/20)))) from x = 0 to 100
    // We use an external library with pre-computed values for below
    // PRICE_PRECISION *(1 - (1 / (2.71828^(x/20)))) from x = 0 to 100
    // plot 1000000 * (1 - (1 / (2.71828^(x/20)))) from x = 0 to 100
    // plot 1000000 * (1 - (1 / (1.7320^(x/20)))) from x = 0 to 100
    // Each epoch can be broken down into 100 discrete points

    function get_total_points(uint8 curve_choice)
        public
        view
        returns (uint256)
    {
        if (curve_choice == 0) return RC_3ROOT_CURVE.length;
        else if (curve_choice == 1) return RC_4ROOT_CURVE.length;
        else if (curve_choice == 2) return RC_5ROOT_CURVE.length;
        else if (curve_choice == 3) return RC_EULER_CURVE.length;
        else if (curve_choice == 4) return RC_PI_CURVE.length;
    }

    function get_curve_point(uint8 curve_choice, uint8 index)
        public
        view
        returns (uint256)
    {
        if (curve_choice == 0) return RC_3ROOT_CURVE[index];
        else if (curve_choice == 1) return RC_4ROOT_CURVE[index];
        else if (curve_choice == 2) return RC_5ROOT_CURVE[index];
        else if (curve_choice == 3) return RC_EULER_CURVE[index];
        else if (curve_choice == 4) return RC_PI_CURVE[index];
    }

    // Square root of 3 curve
    // 1000000 * (1 - (1 / (1.73205807^(x / 20)))) from x = 0 to 100
    uint32[100] public RC_3ROOT_CURVE = [
        27091,
        53449,
        79093,
        104042,
        128315,
        151930,
        174906,
        197259,
        219007,
        240165,
        260751,
        280778,
        300263,
        319220,
        337664,
        355608,
        373065,
        390050,
        406575,
        422652,
        438293,
        453511,
        468316,
        482720,
        496734,
        510369,
        523634,
        536539,
        549095,
        561311,
        573196,
        584759,
        596008,
        606953,
        617601,
        627961,
        638040,
        647847,
        657387,
        666669,
        675699,
        684485,
        693033,
        701349,
        709440,
        717312,
        724971,
        732422,
        739671,
        746724,
        753585,
        760261,
        766756,
        773075,
        779223,
        785204,
        791023,
        796685,
        802193,
        807552,
        812766,
        817838,
        822773,
        827575,
        832246,
        836791,
        841212,
        845514,
        849699,
        853771,
        857733,
        861587,
        865337,
        868985,
        872535,
        875988,
        879347,
        882616,
        885796,
        888890,
        891900,
        894829,
        897678,
        900450,
        903147,
        905771,
        908324,
        910808,
        913224,
        915575,
        917862,
        920087,
        922252,
        924359,
        926408,
        928402,
        930341,
        932228,
        934065,
        935851
    ];

    // Square root of 4 curve
    // 1000000 * (1 - (1 / (2^(x / 20)))) from x = 0 to 100
    uint32[100] public RC_4ROOT_CURVE = [
        34063,
        66967,
        98749,
        129449,
        159103,
        187747,
        215415,
        242141,
        267957,
        292893,
        316979,
        340246,
        362719,
        384427,
        405396,
        425650,
        445215,
        464113,
        482367,
        500000,
        517031,
        533483,
        549374,
        564724,
        579551,
        593873,
        607707,
        621070,
        633978,
        646446,
        658489,
        670123,
        681359,
        692213,
        702698,
        712825,
        722607,
        732056,
        741183,
        750000,
        758515,
        766741,
        774687,
        782362,
        789775,
        796936,
        803853,
        810535,
        816989,
        823223,
        829244,
        835061,
        840679,
        846106,
        851349,
        856412,
        861303,
        866028,
        870591,
        875000,
        879257,
        883370,
        887343,
        891181,
        894887,
        898468,
        901926,
        905267,
        908494,
        911611,
        914622,
        917530,
        920339,
        923053,
        925674,
        928206,
        930651,
        933014,
        935295,
        937500,
        939628,
        941685,
        943671,
        945590,
        947443,
        949234,
        950963,
        952633,
        954247,
        955805,
        957311,
        958765,
        960169,
        961526,
        962837,
        964103,
        965325,
        966507,
        967647,
        968750
    ];

    // Square root of 5 curve
    // 1000000 * (1 - (1 / (2.2360679775^(x / 20)))) from x = 0 to 100
    uint32[100] public RC_5ROOT_CURVE = [
        39437,
        77319,
        113707,
        148660,
        182234,
        214484,
        245463,
        275220,
        303803,
        331259,
        357632,
        382966,
        407300,
        430674,
        453127,
        474694,
        495411,
        515310,
        534425,
        552786,
        570423,
        587364,
        603637,
        619269,
        634284,
        648706,
        662561,
        675868,
        688651,
        700930,
        712724,
        724054,
        734936,
        745389,
        755431,
        765076,
        774340,
        783240,
        791788,
        799999,
        807887,
        815463,
        822741,
        829732,
        836446,
        842896,
        849092,
        855044,
        860760,
        866251,
        871526,
        876593,
        881460,
        886134,
        890625,
        894938,
        899082,
        903062,
        906885,
        910557,
        914084,
        917472,
        920727,
        923853,
        926856,
        929741,
        932512,
        935173,
        937730,
        940186,
        942544,
        944810,
        946987,
        949077,
        951086,
        953015,
        954868,
        956648,
        958357,
        959999,
        961577,
        963092,
        964548,
        965946,
        967289,
        968579,
        969818,
        971008,
        972152,
        973250,
        974305,
        975318,
        976292,
        977226,
        978125,
        978987,
        979816,
        980612,
        981377,
        982111
    ];

    // Euler's constant
    // 1000000 * (1 - (1 / (2.7182818^(x / 20)))) from x = 0 to 100
    uint32[100] public RC_EULER_CURVE = [
        48770,
        95162,
        139292,
        181269,
        221199,
        259181,
        295311,
        329679,
        362371,
        393469,
        423050,
        451188,
        477954,
        503414,
        527633,
        550671,
        572585,
        593430,
        613258,
        632120,
        650062,
        667128,
        683363,
        698805,
        713495,
        727468,
        740759,
        753403,
        765429,
        776869,
        787752,
        798103,
        807950,
        817316,
        826226,
        834701,
        842762,
        850431,
        857725,
        864664,
        871265,
        877543,
        883515,
        889196,
        894600,
        899741,
        904630,
        909282,
        913706,
        917915,
        921918,
        925726,
        929348,
        932794,
        936072,
        939189,
        942155,
        944976,
        947660,
        950212,
        952641,
        954950,
        957147,
        959237,
        961225,
        963116,
        964915,
        966626,
        968254,
        969802,
        971275,
        972676,
        974008,
        975276,
        976482,
        977629,
        978720,
        979758,
        980745,
        981684,
        982577,
        983427,
        984235,
        985004,
        985735,
        986431,
        987093,
        987722,
        988321,
        988891,
        989432,
        989948,
        990438,
        990904,
        991348,
        991770,
        992171,
        992553,
        992916,
        993262
    ];

    // Pi
    // 1000000 * (1 - (1 / (3.14159265358^(x / 20)))) from x = 0 to 100
    uint32[100] public RC_PI_CURVE = [
        55629,
        108163,
        157776,
        204628,
        248874,
        290659,
        330119,
        367384,
        402576,
        435810,
        467195,
        496835,
        524826,
        551259,
        576222,
        599797,
        622060,
        643084,
        662939,
        681690,
        699397,
        716119,
        731911,
        746825,
        760909,
        774209,
        786770,
        798632,
        809834,
        820412,
        830403,
        839837,
        848747,
        857161,
        865107,
        872611,
        879698,
        886390,
        892710,
        898678,
        904315,
        909638,
        914664,
        919412,
        923895,
        928128,
        932126,
        935902,
        939468,
        942835,
        946015,
        949018,
        951854,
        954533,
        957062,
        959450,
        961706,
        963836,
        965848,
        967748,
        969542,
        971236,
        972836,
        974348,
        975775,
        977122,
        978395,
        979597,
        980732,
        981804,
        982816,
        983772,
        984674,
        985527,
        986332,
        987092,
        987810,
        988488,
        989129,
        989734,
        990305,
        990844,
        991353,
        991834,
        992288,
        992717,
        993123,
        993505,
        993866,
        994208,
        994530,
        994834,
        995121,
        995393,
        995649,
        995891,
        996120,
        996335,
        996539,
        996732
    ];

    constructor() {}
}
