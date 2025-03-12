pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

///@title Frens Logo
///@author 0xWildhare and Frens Team
///@dev returns the frens logo svg data as bytes

contract FrensLogo {
  function getLogo() external pure returns (bytes memory){
    return(
      abi.encodePacked(
        '<g opacity="0.25" fill="#00FFFF" transform="matrix(.40,0,0,.40,0,0)">',
          '<path  d="M714.2,516.2c1.8-1,3.3-2,3.9-4.1l0-0.9l-0.6-1c-0.4-0.7-0.8-1.3-1.2-2c-6.7-10.5-13.3-20.9-20-31.4',
          'c10.4-16.5,18.8-33.6,18.8-57.6c0-14.3-2.5-24.3-7.6-30.7c-4.2-5.3-10.3-7.9-18-7.9c-19.7,0-28.5,14.9-35.3,30.2l-54.8-86.1',
          'c-12.1-19-24.2-37.9-36.2-56.9c-10.1-15.9-20.3-31.9-30.4-47.8l-23.1-36.2c-0.8-1.3-2.1-2-3.5-2l0,0c-1.4,0-2.7,0.8-3.5,2.1',
          'c-0.1,0.2-0.2,0.4-0.3,0.5c-0.1,0.2-0.2,0.4-0.3,0.6l-15.6,24.5c-10,15.7-20,31.4-30,47.1l-88.3,138.6c-10.9-5.2-23-8.1-35-8.1',
          'c-23.8,0-51.6,8.6-51.6,32.9c0,9.3,7.9,16,22.1,28.3c5.8,5,12.6,10.8,19.5,17.5c-3.5,5.4-6.9,10.9-10.4,16.3l-1.8,2.8',
          'c-5.1,8-10.3,16.2-15.5,24.3c-0.8,1.3-1.1,2.5-0.9,3.6c0.3,1.1,1,2,2.3,2.7l74.4,42.3c0.2,2.9,0.3,5.9,0.3,9c0,3.5,0.1,6.9,0.4,10.2',
          'l-51.5-30c-6.3-3.7-12.9-7.5-19.3-11.2c-0.7-0.4-2.1-1.1-3.4-0.9c-1.4,0.2-2.5,1-3,2.2c-0.5,1.2-0.4,2.7,0.5,3.8',
          'c1.3,1.9,2.7,3.7,4.1,5.5c0.5,0.7,1.1,1.4,1.6,2.1l8.7,11.6c11.9,15.8,23.8,31.6,35.7,47.4l22.8,30.2c9.3,12.3,18.6,24.7,27.9,37',
          'c10.8,14.3,21.6,28.7,32.4,43l74.2,98.5c0.9,1.2,2.1,1.9,3.4,1.9l0,0c1.3,0,2.5-0.7,3.4-1.9l2.5-3.3c2.7-3.6,5.4-7.2,8.1-10.8',
          'l2.8-3.7c16.8-22.2,33.5-44.5,50.3-66.7c15.5-20.5,30.9-41,46.4-61.5l76.5-101.5c6.8-9,13.6-18,20.3-27c0.4-0.6,0.7-1.2,1-1.8',
          'c0.1-0.3,0.2-0.5,0.4-0.8l0.1-0.2l0-0.2c-0.3-1.9-1.2-3-2.8-3.7c-1.6-0.7-2.9,0.1-4,0.7l-8.2,4.8c-18.9,11-37.9,22-56.8,33',
          'c3.4-8,6.7-16.1,9.8-24.3C675.4,538.3,694.8,527.3,714.2,516.2L714.2,516.2z M660.6,537.6c0-0.1,0.1-0.3,0.2-0.4',
          'c5.1-13.3,12.2-24.9,19.5-36l24.8,11.1L660.6,537.6L660.6,537.6z M703.5,502.8l-3.2-1.4c-3.2-1.4-6.3-2.8-9.4-4.2l-6.1-2.7',
          'c0.1-0.2,0.3-0.4,0.4-0.6c1.1-1.6,2.2-3.2,3.2-4.8c1.1-1.6,2.2-3.3,3.3-4.9L703.5,502.8L703.5,502.8z M510.2,199.3l140.3,220.3',
          'c-2.3,5.4-4.7,10.9-7.6,16c-4.5,7.9-10.3,16.3-15.2,22.9c-5.6-5.9-13.1-9.1-22.1-9.5c-0.9,0-1.9-0.1-2.8-0.1c-2.5,0-4.9,0.2-7.2,0.5',
          'c-0.8-14.4-4-25.8-9.7-33.8c-6.6-9.3-16.3-14.3-29-14.8c-0.6,0-1.2,0-1.8,0c-5.5,0-10.5,1.1-15,3.2c-8.2-12.1-21.5-15-30-15.8',
          'c0-55,0-109.9,0-164.8L510.2,199.3L510.2,199.3z M487.5,438.4c-1.2,1.4-35.1,22.7-41.3,53.6c-3.4-6-7.8-11.6-13.5-16.1l0.7,0.4',
          'c0.1-0.2,8.7-18.6,22.1-36.6l0,0c0,0,0,0,0-0.1c0.8-1,1.5-2,2.4-3.1l0,0c11.4-14.5,27.5-30.1,44.4-30.6l0,0c0.7,0,1.3,0,2,0',
          'c1,0,2,0.1,3,0.2c0,0,0,0,0,0c1,0.1,2,0.1,2.9,0.3l0,0c11.7,1.3,21.1,6.2,20.2,27.3c-1.4,33.1-41.2,85.6-55,85',
          'c-8.2-0.3-17.8-3.8-17.2-18.4c1.2-29.5,29.6-62,29.9-62.3L487.5,438.4L487.5,438.4z M500.2,518.6c20.8-20.3,41.7-58.1,42.8-84.5',
          'c0.2-3.9,0-7.4-0.3-10.6c1.2-1.4,5-5,13.4-4.6c7.9,0.3,24.5,1,22.7,43.4c0,0.2,0,0.3,0,0.5c-0.2,0.4-0.3,0.6-0.4,0.8l0.4,0.2',
          'c-2.6,39.1-41.4,84.4-59.7,83.7c-7.2-0.3-12.3-2.7-15.4-7.1C498.5,533,499.8,521.7,500.2,518.6L500.2,518.6z M555.6,540.2',
          'c3.3-3.5,6.4-7.2,9.1-10.8c14.6-19.1,23.9-40.7,26.3-60.1c2-1.1,6.1-2.5,13.8-2.2c4.4,0.2,17.8,0.7,16.7,26.3',
          'c-1.2,29.3-30.1,71.8-48.2,71.1c-8.3-0.3-13.8-2.8-16.5-7.2C553.5,552,554.6,544.1,555.6,540.2L555.6,540.2z M502.2,199.5v22.1',
          'c0,55.4,0,110.8,0,166.1c-19.1,0.4-38.4,13.1-57.6,37.7c-12,15.4-20.6,31.4-24.4,38.8c-4.5-1.8-9.4-3.1-14.5-3.9',
          'c0.4-3.4,0.6-6.9,0.6-10.5c0-17.5-8.4-33.7-23.6-45.7c-2.4-1.9-4.9-3.6-7.5-5.2L502.2,199.5L502.2,199.5z M329,471.5',
          'c4.8,4.9,9.6,10.3,14.1,16.1l-33.7,15c-0.1,0.1-0.3,0.1-0.4,0.1L329,471.5L329,471.5z M307.5,512.3l40.5-18',
          'c10.5,15,19,32.7,22.3,53.8L307.5,512.3L307.5,512.3z M502.3,779.9v22.5L313.7,552.1c0.5,0.3,0.9,0.5,1.4,0.8l25.6,14.9',
          'c10.8,6.3,21.8,12.7,32.7,19c9.1,55,55.5,80.1,89.5,80.1c12.4,0,23.6-2.9,33.4-8.6c1.4,0.8,2.7,1.6,4.1,2.4c1.5,0.9,2,1.7,2,3.5',
          'C502.3,702.8,502.3,742,502.3,779.9L502.3,779.9z M672.8,567.3l26-15.1c0,0,0,0,0,0L510.3,802.2c0-0.2,0-0.4,0-0.6v-32.8',
          'c0-35.2,0-70.4,0-105.6c0-0.3,0-0.6,0.1-0.8c9.3,2.9,21.7,4.4,37,4.4c28.4,0,52-14,72.2-42.9c8-11.5,14.9-24.4,21.2-38',
          'C651.4,579.7,662.1,573.5,672.8,567.3L672.8,567.3z M620.5,588.5L620.5,588.5c-0.5,1.1-1.1,2.2-1.7,3.2c-0.1,0.2-0.2,0.3-0.3,0.5',
          'c-0.5,1-1,2-1.5,2.9c0,0.1-0.1,0.2-0.1,0.2c-1.2,2.2-2.4,4.3-3.6,6.4c-17.1,29.6-37.2,48.3-66,48.3c-6.2,0-11.4-0.2-15.8-0.7l0,0',
          'c-5-0.5-9.1-1.2-12.3-1.9l0,0c-5.9-1.4-9.1-3.1-10.8-4.3c20.2-22.5,24.3-58.9,17.4-80V563c0,0.2-0.5,22.8-8.9,44.8',
          'c-1.9,5-4.1,9.7-6.5,13.8c-1.2,2-2.4,3.9-3.7,5.7c0,0,0,0.1-0.1,0.1c-1.3,1.8-2.6,3.5-4,5.1c-4.4,5-9.3,8.9-14.7,11.8',
          'c-0.7,0.4-1.4,0.7-2.1,1c-0.1,0-0.2,0.1-0.3,0.2c-0.6,0.3-1.2,0.5-1.9,0.8c-0.1,0.1-0.3,0.1-0.4,0.2c-0.6,0.2-1.2,0.5-1.9,0.7',
          'c-0.1,0-0.3,0.1-0.4,0.1c-0.8,0.2-1.5,0.5-2.3,0.7c-4.9,1.4-10.1,2.1-15.6,2.1c-19.6,0-56-13.3-69.2-51.5l0,0c-1.2-3.4-2.2-7-3-10.9',
          'c-1.3-6.4-2-13.3-2-20.9c0-1.4,0-2.7-0.1-4c0-0.2,0-0.4,0-0.6c-1-32.1-12.4-57.7-27-78.2c-0.1-0.1-0.1-0.2-0.2-0.2',
          'c-0.8-1.1-1.5-2.1-2.3-3.2l0,0l0,0c-6.6-8.8-13.7-16.7-20.8-23.6l0,0c-1-1-1.9-1.9-2.9-2.8c0,0,0,0,0,0c-1-0.9-1.9-1.8-2.9-2.7l0,0',
          'l0,0c-6.3-5.9-12.4-11.1-17.8-15.8c-6.8-5.8-15.2-13.1-16.3-15.8c0.3-12.5,22.9-15.8,34.8-15.8c9.6,0,18.4,2,26,5.4',
          'c1.1,0.5,2.2,1,3.3,1.6c0.2,0.1,0.4,0.2,0.6,0.3c1.1,0.6,2.1,1.2,3.2,1.8c15.1,9.2,24.2,23.9,24.2,37.7c0,24.9-2.6,43.1-2.6,43.1',
          'c0.5-0.7,6-6.2,10-17.4c25.4,2,39.8,16.7,47.9,32.8c0.9,4.5,2.5,8.5,4.9,11.8c5.5,16.5,5.7,31.7,5.7,33.1c0-0.3,1.5-12.2,0-27.2',
          'c4.8,3.6,11,5.8,18.2,6.1c3.8,0.2,8-1.2,12.5-3.8c0.4,6.3,2,13.8,6.3,20c5.5,7.9,13.9,12.2,25,12.6c7.5,0.3,15.7-3.5,23.6-9.3',
          'c0.4,4.2,1.6,8.7,4,12.8c5.1,8.4,14,13,26.6,13.5c26.9,1.1,60.2-50.3,61.6-84.7c0.2-5.6-0.1-10.6-1-15.2',
          'c5.7-7.2,16.6-21.5,24.2-34.9c2.2-3.8,4-7.6,5.7-11.4c0.1-0.1,0.1-0.3,0.2-0.4c0.6-1.4,1.2-2.7,1.8-4.1c0,0,0,0,0,0l0,0',
          'c0.6-1.4,1.2-2.7,1.7-4.1c7.2-16.9,11.8-26.4,22.7-26.4c3.2,0,8.8-0.5,8.8,21.8c0,16.8-4.9,29.4-12.1,41.9c-0.7,1.2-1.5,2.5-2.2,3.7',
          'l0,0c-0.8,1.2-1.5,2.5-2.3,3.7c-3.3,5.1-6.9,10.3-10.6,15.9c-9.4,14.1-19.2,28.7-26.1,46.7c-2.6,6.8-5.2,13.3-7.8,19.7',
          'c-1.6,4-3.3,8-4.9,11.9l0,0C628.4,571.9,624.6,580.5,620.5,588.5L620.5,588.5z"/>',
        '</g>'
      )
    );
  }
}
