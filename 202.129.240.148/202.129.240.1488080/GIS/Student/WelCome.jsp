




<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>GIS Student Login</title>
        <link type="text/css" href="../menu/menu.css" rel="stylesheet" />
        <link type="text/css" href="../menu/style.css" rel="stylesheet" />
        <link type="text/css" href="../menu/calendar-blue2.css" rel="stylesheet" />
        <script type="text/javascript" src="../menu/jquery.js"></script>
        <script type="text/javascript" src="../menu/menu.js"></script>
        <script type="text/javascript" src="../menu/calendar.js"></script>
        <script type="text/javascript" src="../menu/calendar-en.js"></script>
        <script type="text/javascript" src="../menu/calendar-setup.js"></script>
        <script type="text/javascript">
           function open_win()
            {
                 if(document.f1.quiz_id.value=="")
                        {
                            alert('Select quiz_id');
                            document.f1.quiz_id.focus();
                            return false;
                        }
            }
            
        </script>
    </head>
    <body>
       <table width="100%">
           <tr>
               <td width="130"><img src="../image/logo.gif" width="80" height="90" ></td>
               <td class="institute" valign="center">G H Patel College of Engineering & Technology</td>
           </tr>
           <tr>
               <td colspan="2" class="tablemenu">

<table width="100%">
    <tr>
        <td> 
            <div id="menu">
                <ul class="menu">
                    <li><a href="/GIS/Student/WelCome.jsp" class="parent"><span>Home</span></a></li>
                    <li><a href="#" class="parent"><span>Material</span></a>
           <div><ul>
                <li><a href="/GIS/Student/ViewUploadMaterialNew.jsp" class="parent"><span>View Uploaded Material</span></a>
                </li>
                <li><a href="/GIS/Student/ViewUploadMaterialNew_1.jsp" class="parent"><span>View Uploaded Material (Search)</span></a>
                </li>
                </ul>
            </div>
                        
         <!--    <li><a href="/GIS/Councelling/ViewAssignCounsiler.jsp" class="parent"><span>Counsellor Allocation</span></a> -->
        </li>
                    <li><a href="/GIS/Student/ViewMyAttendance.jsp" class="parent"><span>View Attendance</span></a></li>
                    <li><a href="/GIS/Student/FirstYear/FirstYearDataEntry.jsp" class="parent"><span><b>First Year Data Entry</b></span></a></li> 
                    <!-- <li><a href="http://10.10.12.124:8080/Library/" class="parent"><span>e-Library</span></a></li> -->
                    <li><a href="#" class="parent"><span>Quiz</span></a>
                        <div>
                            <ul>
                                <li><a href="/GIS/Student/Quiz_Result.jsp" class="parent"><span>Quiz Result</span></a></li>
                                <li><a href="/GIS/Student/ViewSolution.jsp" class="parent"><span>Quiz Solution</span></a></li>
                            </ul>
                        </div>
                    </li> 
                    <li><a href="#" class="parent"><span>Library</span></a>
                        <div>
                            <ul>
                                <li><a href="https://drive.google.com/drive/folders/1sM_PjyU_aFBywSsdtCIxQwAcJjGsEfnD?usp=sharing" class="parent" target="_blank"><span>Mid SEM ePaper</span></a></li>
                                <li><a href="https://drive.google.com/drive/folders/1C22Uua3mp_AOED7hVVdB4ulLidIr-1OP?usp=sharing" class="parent" target="_blank"><span>Mid SEM ePaper (AY2024-25)</span></a></li>

                            </ul>
                        </div>
                    </li> 
                    
           
                   
                    <li><a href="#" class="parent"><span>Academic Calendar</span></a>
                        <div>
                            <ul>
                            <li><a target="_blank" href="/GIS/Student/Aca_2024-25_Even_SEM4_6.pdf" class="parent"><span>SEM 4 & 6</span></a></li>
                            <li><a target="_blank" href="/GIS/Student/Aca_2024-25_Even_SEM2.pdf" class="parent"><span>SEM 2</span></a></li>
                            <li><a target="_blank" href="/GIS/Student/Aca_2024-25_Even_SEM2_Diploma.pdf" class="parent"><span>SEM 2 (Diploma)</span></a></li>
                            <!-- <li><a target="_blank" href="/GIS/Student/Aca_2024-25_Odd_SEM1.pdf" class="parent"><span>SEM 1</span></a></li>
                            <li><a target="_blank" href="/GIS/Student/Aca_2024-25_Odd_SEM3_5.pdf" class="parent"><span>SEM 3 & 5</span></a></li>
                            <li><a target="_blank" href="/GIS/Student/Aca_2024-25_Odd_SEM7.pdf" class="parent"><span>SEM 7</span></a></li>
                            <li><a target="_blank" href="/GIS/Student/Aca_2024-25_Odd_SEM3_Diploma.pdf" class="parent"><span>SEM 3 Diploma</span></a></li>
                               
                            <!--
                                <li><a target="_blank" href="/GIS/Student/Aca_2023-24_Odd_SEM1_Diploma.pdf" class="parent"><span>Diploma SEM1</span></a></li>
                                <li><a target="_blank" href="GIS/Student/Aca_2023-24_Odd_SEM3.pdf" class="parent"><span>B.Tech. SEM3</span></a></li>
                                <li><a href="/GIS/Student/Aca_2023-24_Odd_SEM5_7.pdf" calss="parent"><span>SEM 5 and 7</span></a></li>
                            -->
                            
                            <!-- <li><a href="/GIS/Student/Aca_2022-23_Even_SEM4.pdf" calss="parent"><span>SEM 4</span></a></li> 
                            <li><a href="/GIS/Student/Aca_2022-23_Even_SEM6.pdf" calss="parent"><span>SEM 6</span></a></li> 
                              -->
                            
                           </ul>
                        </div>
                    </li> 
                    
                    
         <!--           <li><a href="/GIS/Student/Upload_Aadhaar_Card.jsp" class="parent"><span>Register Aadhaar Card</span></a></li> -->
                    <li><a href="/GIS/Student/Profile/ChangePassword.jsp" class="parent"><span>Change Password</span></a></li>
                    <li><a href="/GIS/StudentLogout.jsp" class="parent"><span>Logout</span></a></li>
                </ul>
                <div id="copyright"> <a href="http://apycom.com/"></a></div>
            </div>
        </td>
    </tr>
</table></td>
           </tr>
        </table>
        <br>
        
            <table class="tablelogin" cellspacing="5">
                <tr>
                    <th valign="middle">Login Successfully</th>
                </tr> 
            </table>
            <br>
            <table class="tablelogin" cellspacing="5">
                <tr>
                    <td>Enrollment No:</td>
                    <td>12502040503011</td>
                </tr>
                <tr>
                    <td>Name:</td>
                    <td>GUNDARWALA YUSUF</td>
                </tr>
                <tr>
                    <td>Registered Email :</td>
                    <td>yusufgunderwala0@gmail.com</td>
                </tr> 
            </table><br/>
            
                
                    <table  class="tablematerial" cellspacing="2" cellpadding="5">
                         <tr>
                            <th>Enrollment No: 12502040503011</th>
                            </tr>
                            <tr>
                            <th>Name : GUNDARWALA YUSUF</th>
                            </tr>
                       
                           
                            
                            
                                    
                            
                            
                                <td class="present">Registration is permitted provided that student remains present on first day of registration.</th>
                                
                        
                    </table>
                    <br>
                
            
                 
                <table  class="tablematerial" cellspacing="2" cellpadding="5">
                  <tr>
                        <th>Sr No</th>
                        <th>Course Code</th>
                        <th>Course Name</th>
                        <th>Practical Batch</th>
                        <th>Class</th>
                        <th>Semester</th>
                        <th>Elective</th>
                    </tr>
                    
                    <tr>
                    <td class="tablematerial1">1</td>
                    <td class="tablematerial1">202003404</td>
                    <td class="tablematerial1">TECHNICAL WRITING AND SOFT SKILL</td>
                    <td class="tablematerial1">1D4</td>
                    <td class="tablematerial1">1</td>
                    <td class="tablematerial1">IV</td>
                    <td class="tablematerial1">-</td>
                    
                    
                        
                              
                        
                            
                    
                    
                    <tr>
                    <td class="tablematerial2">2</td>
                    <td class="tablematerial2">202003405</td>
                    <td class="tablematerial2">ENTREPRENEUR SKILLS</td>
                    <td class="tablematerial2">1D4</td>
                    <td class="tablematerial2">1</td>
                    <td class="tablematerial2">IV</td>
                    <td class="tablematerial2">-</td>
                    
                    
                        
                        
                              
                            
                    
                    
                    <tr>
                    <td class="tablematerial1">3</td>
                    <td class="tablematerial1">202040401</td>
                    <td class="tablematerial1">COMPUTER ORGANIZATION AND ARCHITECTURE</td>
                    <td class="tablematerial1">1D4</td>
                    <td class="tablematerial1">1</td>
                    <td class="tablematerial1">IV</td>
                    <td class="tablematerial1">-</td>
                    
                    
                        
                              
                        
                            
                    
                    
                    <tr>
                    <td class="tablematerial2">4</td>
                    <td class="tablematerial2">202040402</td>
                    <td class="tablematerial2">OPERATING SYSTEMS</td>
                    <td class="tablematerial2">1D4</td>
                    <td class="tablematerial2">1</td>
                    <td class="tablematerial2">IV</td>
                    <td class="tablematerial2">-</td>
                    
                    
                        
                        
                              
                            
                    
                    
                    <tr>
                    <td class="tablematerial1">5</td>
                    <td class="tablematerial1">202040404</td>
                    <td class="tablematerial1">SEMINAR</td>
                    <td class="tablematerial1">1D4</td>
                    <td class="tablematerial1">1</td>
                    <td class="tablematerial1">IV</td>
                    <td class="tablematerial1">-</td>
                    
                    
                        
                              
                        
                            
                    
                    
                    <tr>
                    <td class="tablematerial2">6</td>
                    <td class="tablematerial2">202040405</td>
                    <td class="tablematerial2">DISCRETE MATHEMATICS</td>
                    <td class="tablematerial2">1D4</td>
                    <td class="tablematerial2">1</td>
                    <td class="tablematerial2">IV</td>
                    <td class="tablematerial2">-</td>
                    
                    
                        
                        
                              
                            
                    
                    
                    <tr>
                    <td class="tablematerial1">7</td>
                    <td class="tablematerial1">202044502</td>
                    <td class="tablematerial1">PROGRAMMING WITH JAVA</td>
                    <td class="tablematerial1">1D4</td>
                    <td class="tablematerial1">1</td>
                    <td class="tablematerial1">IV</td>
                    <td class="tablematerial1">-</td>
                    
                    
                        
                              
                        
                            
                    
                    
                </table>
                <br>
            <form name="f1" action="quiz_index_1.jsp" method="post" onsubmit="return open_win();">
            <table class="tablelogin" cellspacing="5">
                <tr>
                            <td>Quiz ID</td>
                            <td>
                       
                             
                            
                            <select name="quiz_id">
                                <option value="">--Select--
                                    

                            </select>
                                
                            </td>
                            <td>
                                <INPUT type="hidden" name="enrollment_no" value="12502040503011"> 
                                <INPUT type="submit" value="Start"> 
                            </td>
                        </tr>
            </table>
            <br>
        </form>
    </body>
</html>

