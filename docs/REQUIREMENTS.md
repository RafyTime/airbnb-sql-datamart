# PORTFOLIO

## Assignments for the course: Build a Data Mart in SQL (DLBDSPBDM01)

## 1. TOPICS AND TASKS

Within the framework of this course, the following topic must be selected.

### **1.1. Task: A Use-Case of booking a hotel room: Airbnb**

Databases are becoming more and more important nowadays. Within this section you will find a description for
your tasks regarding the definition and creation of a database for renting apartments and bedrooms. You know
this use case from Airbnb. According to the company’s founding legend, the idea was born in October 2007, based
on personal experience with an overpriced shared apartment and fully booked hotels due to a well-attended con-
ference in San Francisco. The original name Airbedandbreakfast was shortened to Airbnb in 2009. As an online
platform, the company establishes the contact between host and guest and is solely responsible for handling the
booking. The transaction takes place via the platform. The guest pays the amount for his booking by credit card
to Airbnb. The host is not paid until 24 hours after arrival to ensure that the guest finds the accommodation as it
is described on the platform. In 2013, Airbnb earned 6-12% commission from guests, 3% from hosts and a total of
$150 million from about 10 million overnight stays. Further Details can be found on [http://www.Airbnb.com.](http://www.Airbnb.com.)

Each user, i.e. host and guest, presents himself on Airbnb with a profile page. Hosts have to upload at least one
picture and enter a phone number. Guests have to provide even more information. Hosts can describe their ac-
commodation textually and by using photos. Guest and host can rate each other. Using the platform’s calculator
function, you can calculate the expected income with your own accommodation. Since 2011 it is possible to con-
nect your profile with social networks like Facebook. This enables the display of an Airbnb user's ratings through
social contacts.

Within the framework of this course, you have to build and document an appropriate database including data,
which is self-developed regarding the data model you build.

**The task:** You have to build a database for storing and processing information regarding the Airbnb use case.
Therefore, the first step is to develop an entity relationship model (ERM), which describes the single data tables
with its attributes and the relations between these entities. This ERM is the basis for developing a database with
a state-of-the-art database management system (e. g.: <https://www.mysql.com/>). You are free to choose every
database management system which uses SQL as a basic language. Define a database structure and certain rea-
sonable dummy data by yourself, to ensure an appropriate usage of the database and some feasible queries to
present the results in a document. Please ensure that every step and written SQL Statement is being documented
as described in the implementation phase. Furthermore, the database has to be normalized in an appropriate
way to ensure only necessary data storage.

Make sure that you have filled up your database with appropriate dummy data, to ensure testing and results are
showing up. Use reasonable data of your own choice.

Your database management system needs to be built, documented and delivered according to the following three
phases:

#### **1.1.1. Conception phase**

This part of the database design process is called database modelling and represents the most important part of
the database design. Anything that is overlooked or forgotten in this phase has a negative effect on the implemen-
tation later and will lead, in the worst case, to a useless database.

The first step is to **create a requirements specification** for your project Airbnb. The specification document must
contain a requirements analysis, which addresses the following aspects in more detail:
o What roles (person/user groups) are there?
o What actions do these roles perform?
o Which data and functions are required?

The requirements specification should **not exceed two pages in 12-point font.**

In addition to the specification document, **create an Entity Relationship Model (ERM)**. Create a meaningful ER-
Model from your requirements specification. The requirements for the ER-Model are:
o The model should contain at least 20 entities.
o The model should contain 2-3 triple relationships (Join over three tables.).
o The model may also contain recursive relationships. Assign suitable attributes to the entities and mark
the key attributes.
o Specify all cardinality specifications in a notation of your choice (e. g. Chen notation)
o Short description of your current attributes in a data dictionary (short description of the data attributes
and data types are appropriate).

Remember that your ER model must be consistent with the roles, actions and data described in the requirements
specification.

Please also provide **a half-page description** (summary or abstract) **of your work and the single working steps
within this phase**. A brief description of the existing problem, your solution approaches regarding the database
development.

Throughout the process, online tutorials are offered, and they provide an opportunity to talk, share ideas and/or
drafts, and obtain feedback. In the online tutorials, exemplary work can be discussed with the tutor. Here, every-
one has the opportunity to get involved and learn from each other's feedback. **It is recommended to make use
of these channels to avoid errors and to make improvements.** You should only submit work after making use
of the above-mentioned tutorial and informative media. This will be followed by a feedback from the tutor and
the work on the second phase can begin.

#### **1.1.2. Development phase/reflection phase**

Within this phase you will start to **implement your own database management system for the Airbnb Use Case**.
Please ensure, that every SQL-Statement is written down in your database file and is well documented.
o Ensure that you deliver tables and relations for the database in a sql-datafile as you outline the concept
in your ER-Diagram
o Document every SQL-Statement regarding the creation process
o Ensure that every table has at least a minimum of 20 entries
o To test your first development, ensure that you have at least one test case for your database regarding
the ER-Model

In this phase you must submit an **explanation of your database design and implementation procedure as a
composite presentation PDF with at least 20 slides** (regarding you ER model). The slides should contain the
documentation of the sql-statements (for each Entity one slide) with the corresponding test case (sql-statement)

and a screenshot of the result shown in the database management system. Please also provide **a brief summary
of the implementation (approx. 1/2 page).**

Throughout the process, online tutorials and other channels provide the opportunity to profoundly discuss ideas
and/or drafts and to get sufficient feedback, tips, and hints. **It is recommended to use these channels to avoid
errors and to improve your work.** Once this is done, you can hand in your second phase for evaluation. Following
a feedback from the tutor, your work on the final draft will continue in the third phase.

#### **1.1.3. Finalization phase**

In this final phase, your goal is to **polish and refine your database management system** , after having received
feedback from the tutor, and prepare it for final submission. Certain elements may have to be improved or
changed to finalize the task and complete this portfolio course.

In a final step you write a **2 - page abstract PDF document** in which you highlight and describe your database
management functionality and also provide metadata stored in the system: number of tables and corresponding
entries and the size of the database regarding its volume.

You have finished your product (database system for Airbnb) once you have delivered all the files, SQL-files (in-
cluding documentation and installation manual) and presentations as a **single ZIP-File and put it into a folder**.
You have to **zip this folder and insert it in your submission in PebblePad**. In addition, provide a **pdf-document
with all results from each phase including the slides and screenshots** you have made during the three phases
and upload the file into PebblePad.

In the “Finalization phase”, the online tutorials and other channels also provide the opportunity to obtain suffi-
cient feedback, tips, and hints before the finished product is finally handed in. **It is recommended to use these
channels to avoid errors and to make improvements.** The finished product is submitted with the results from
Phase 1 and Phase 2 and together with the materials mentioned above. Following the submission of the third
portfolio page, the tutor submits the final feedback which includes evaluation and scoring within six weeks.

## 2. TUTORIAL SUPPORT

In principle, several channels are open to attain feedback for the portfolios. The respective use is the sole respon-
sibility of the user. The independent development of a product and the work on the respective portfolio parts is
part of the examination performance and is included in the overall assessment.

On the one hand, the tutorial support provides feedback loops on the portfolio parts to be submitted in the con-
text of the conception phase as well as the development and reflection phase. The feedback takes place within
the framework of a submission of the respective part of the portfolio. In addition, regular online tutorials are of-
fered. These provide you with an opportunity to ask any questions regarding the processing of the portfolio and
to discuss other issues with the tutor. The tutor is also available for technical consultations as well as for formal
and general questions regarding the procedure for portfolio management.

Technical questions regarding the use of “PebblePad” should be directed to the exam office via mail.

## 3. EVALUATION

The following criteria are used to evaluate the portfolio with the percentage indicated in each case:

| Evaluation Criteria            | Explanation                                                                                                                        | Weighting |
|-------------------------------|------------------------------------------------------------------------------------------------------------------------------------|-----------|
| Problem Solving Techniques     | • Capturing the problem<br>• Clear problem definition/objective<br>• Understandable concept                                         | 10%       |
| Methodology/Ideas/Procedure   | • Appropriate transfer of theories/models<br>• Clear information about the chosen Methodology/Idea/Procedure                        | 20%       |
| Quality of implementation      | • Quality of implementation and documentation                                                                                      | 40%       |
| Creativity/Correctness         | • Creativity of the solution approach<br>• Solution implemented fulfils intended objective                                         | 20%       |
| Formal requirements            | • Compliance with formal requirements                                                                                              | 10%       |

The design and construction of the portfolio should take into account the above evaluation criteria, including the
following explanations:

**Problem Solving Techniques:** According to the problem of creating a database in the context of Airbnb, you
should be able to design and implement a database with a clear documentation as a technical basis for applica-
tion development and data organisation.

**Methodology/idea/procedure:** According to the database design, you should be able to transfer a practical prob-
lem regarding the usage of a common modelling language like ER-Modelling into a technical representation of
data within a database. The idea is to generate an entity relationship model in a first step as a starting point for
discussions and improvements. Afterwards the documented ER-Model is used as a starting point for the actual
implementation. Describe and also explain why you choose a specific entity and justify this with the criteria of the
portfolio course.

**Quality of implementation** **_:_** A clear concept of the implementation and the possible operation of it by a user who
is not familiar with the project will be evaluated. The possibility of creating the database with your SQL definitions
in another database management system and the consistency of the results are also included in the evaluation.

**Creativity/Rightness:** It is evaluated whether the specific requirements have been understood and implemented
in a comprehensible and innovative way. The basic functionality of the database must be covered by showing and
describing the results of your queries.

**Formal requirements:** The submission follows the acceptance criteria from Chapter 1 and the formal guidelines
following in the next chapter. It is particularly important to respect the formal submission requirements outlined
in Chapter 4.

## 4. FORMAL GUIDELINES AND SPECIFICATIONS FOR SUBMISSION

### **4.1. Components of the examination performance**

The following is an overview of the examination performance portfolio with its individual phases, individual per-
formances to be submitted, and feedback stages at one glance. A template in “PebblePad” is provided for the
development of the portfolio parts within the scope of the examination performance. The presentation is part of
this examination.

| Stage / Phase                    | Intermediate Result / Portfolio Part                                                                                                              | Performance to be Submitted                                                                                                                                                                                                                                                                                       |
|----------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Conception phase**             | Portfolio part (1):<br>• ½ page summary of the existing problem and solution approaches regarding database development for the text field in PebblePad | - Two-page concept in written form<br>- Comprehensive ER-Model included within one PDF document                                                                                                                                                                                                                    |
| **Development / Reflection phase** | Portfolio part (2):<br>• ½ page summary for the text field in PebblePad                                                                           | - Written explanation of implementation as a composite presentation PDF with about 20 slides, including:<br>  - Screenshots of results<br>  - SQL-Statements                                                                                                                                                      |
| **Finalization phase**           | Portfolio part (3):<br>• 2-page abstract ("making of")                                                                                            | - Final product (SQL scripts with installation data insert queries, documentation included)<br>- One PDF document with all information and content (including screenshots) of all three phases<br>- Upload a ZIP folder (including all files)<br>- Result from phase 1<br>- Result from phase 2                |

### **4.2. Format for Digital File Submission**

**Conception phase**

Recommended tools/software for
processing

- Word or LaTex (pdf-File for submission)
- Tools to draw ER-Models (e. g. Visio, SmartDraw, Edraw)
- Relevant sources in digital forms

Permitted file formats PDF

File size as small as possible

Further formalities and parameters Files must always be named according to the following pattern:

```
For the performance-relevant submissions on “PebblePad”:
Name-FirstName_MatrNo_Course_P(hase)-1_S(ubmission)
Example: Mustermann-Max_12345678_ DLBDSPBDM01_P1_S
```

**Development/reflection phase**

Recommended tools/software for
processing

- PowerPoint or LaTex (pdf-File for submission)
- SQL data files (.sql-Data)
- Relevant sources in digital forms

Permitted file formats PDF and (.sql-Files)

File size as small as possible

Further formalities and parameters Files must always be named according to the following pattern:

```
For the performance-relevant submissions on “PebblePad”:
Name-FirstName_MatrNo_Course_P(hase)- 2 _S(ubmission)
Example: Mustermann-Max_12345678_ DLBDSPBDM01_P2_S
```

**Finalization phase**

Recommended tools/software for
processing

- Word or LaTex (pdf-File for submission)
- Relevant sources in digital forms

Permitted file formats (^) • PebblePad: PDF

- Zip folder: various file formats for submissions from all three phases. The
    code (.sql-files) must be inserted in the folder by creating a ZIP file from all
    the files.

File size (^) • PebblePad: Max. 25MB

- Zip folder: Max. 150 MB

Further formalities and parameters **IMPORTANT** is the upload of the zip folder that has been created especially for the sub-
mission (please follow the instructions on myCampus). This folder contains all the files
you used to complete the task. To ensure a better overview, please create subdirecto-
ries for this purpose.

```
The folder structure then looks like this:
o Main directory (name of the zip folder) -> Name: Last_Name-First_Name_Ma-
triculation_Course
o Subdirectory -> Name: 01-Concept
o Subdirectory -> Name: 02-Development
o Subdirectory -> Name: 03-Finalisation
```

```
In phase 3 you should also upload a zipped version (ZIP file with all program code) to
a zip folder with the following naming convention: Name-First-
Name_MatrNo_Course_Topic_Submission_Code.zip
Example: Mustermann-Max_12345678_DLBDSPBDM01_Data_Mart_Submis-
sion_all.zip
```

```
Files must always be named according to the following pattern:
```

```
For the performance-relevant submissions on “PebblePad”:
Name-FirstName_MatrNo_ Course _P(hase)-3_S(ubmission)
Example: Mustermann-Max_12345678_ DLBDSPBDM01_P3_S
```

#### IU.DE

### **4.3. Format of Abstract**

| Requirement       | Details                                                                                              |
|-------------------|------------------------------------------------------------------------------------------------------|
| Length            | 2 pages of text                                                                                      |
| Paper size        | DIN A                                                                                                |
| Margins           | Top and bottom: 2cm; Left: 2cm; Right: 2cm                                                          |
| Font              | General Text: Arial 11 pt.; Headings: 12 pt., Justify                                               |
| Line Spacing      | 1                                                                                                    |
| Sentences         | Justified; hyphenation                                                                               |
| Footnotes         | Arial 10 pt., Justify                                                                                |
| Paragraphs        | According to mental structure; 6 pt. after line break                                                |
| Affidavit         | The affidavit shall be made in electronic form via “myCampus”. No submission of the examination performance is possible before it. |

```txt
Please follow the instructions for submitting a portfolio on “myCampus”.
```

If you have any questions regarding the submission of the portfolio, please contact the exam office via mail.

Please also note the instructions for using PebblePad & Atlas!

Good luck creating your portfolio!
