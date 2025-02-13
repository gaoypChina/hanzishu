import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hanzishu/engine/fileio.dart';
import 'package:hanzishu/engine/lesson.dart';
import 'package:hanzishu/engine/paintsoundmanager.dart';
import 'package:flutter/material.dart';
import 'package:hanzishu/ui/imagebutton.dart';

import 'package:hanzishu/variables.dart';
import 'package:hanzishu/data/levellist.dart';
import 'package:hanzishu/utility.dart';
import 'package:hanzishu/ui/lessonpage.dart';
import 'package:hanzishu/data/lessonlist.dart';
import 'package:hanzishu/localization/string_en_US.dart';
import 'package:hanzishu/localization/string_zh_CN.dart';
import 'package:hanzishu/ui/paintsoundpage.dart';
import 'dart:ui';
import 'dart:io';

class LessonsPage extends StatefulWidget {
  @override
  _LessonsPageState createState() => _LessonsPageState();
}

var courseMenuList = [
  // allocate local language during run time
  CourseMenu(1, 429),
  //CourseMenu(2, 423),
  //CourseMenu(3, 424),
  //CourseMenu(4, 425),
  //CourseMenu(5, 426),
];

class _LessonsPageState extends State<LessonsPage> {
  bool hasLoadedStorage;
  int newFinishedLessons;

  String currentLocale;

  double screenWidth;

  List<DropdownMenuItem<CourseMenu>> _dropdownCourseMenuItems;
  CourseMenu _selectedCourseMenu;

  int currentSoundPaintSection;
  SoundCategory currentSoundCategory;

  //_openLessonPage(BuildContext context) {
  //  Navigator.of(context).push(MaterialPageRoute(builder: (context) => LessonPage()));
  //}
  // starting lesson number in each row
  //final List<int> lessons = <int>[1, 2, 3, 5, 6, 8, 9, 11, 13, 16, 18, 19, 21, 22, 24, 26, 29, 31, 32, 34, 36, 37, 39, 41, 44, 46, 47, 49, 50, 53, 56, 59];
  //final List<int> lessons = <int>[1, 2, 4, 6, 7, 10, 11, 13, 16, 17, 18, 20, 22, 23, 25, 27, 28, 30, 33, 34, 35, 37, 39, 40, 42, 44, 45, 48, 50, 51, 53, 54, 55, 57, 60];
  final List<int> lessons = <int>[
       1, 2, 4, 5, 7, 9,//1, 2, 4, 6, 8,
       10, 11, 13, 15,
       17, 18, 20,
       22, 23, 25,
       27, 28, 30, 32,
       34, 35, 37,
       39, 40, 42,
       44, 45, 47, 49,
       50, 51, 53,
       54, 55, 57, 59, 60];

  double getSizeRatioWithLimit() {
    return Utility.getSizeRatioWithLimit(screenWidth);
  }

  @override
  void initState() {
    super.initState();

    setState(() {
      this.hasLoadedStorage = false;
      this.newFinishedLessons = 0;
      currentSoundCategory = SoundCategory.hanzishuLessons;
      currentSoundPaintSection = 0;
      _dropdownCourseMenuItems = buildDropdownCourseMenuItems(courseMenuList);
      _selectedCourseMenu = _dropdownCourseMenuItems[0].value;
    });
  }

  handleStorage() {
    // doing nothing for web for now
    if (!kIsWeb) {
      if (!theStorageHandler.getHasTriedToLoadStorage()) {
        var fileIO = CounterStorage();
        theFileIOFile = fileIO;
        theStorageHandler.setHasTriedToLoadStorage();
        fileIO.readString().then((String value) {
          // just once, doesn't matter whether it loads any data or not
          if (value != null) {
            var storage = theStorageHandler.getStorageFromJson(value);
            if (storage != null) {
              updateDefaultLocale(storage.language);
              theStorageHandler.setStorage(storage);
              setState(() {
                this.hasLoadedStorage = true;
              });
            }
          }
        });
      }
    }
  }

  void updateDefaultLocale(String localeFromPhysicalStorage) {
    if (localeFromPhysicalStorage != null && (localeFromPhysicalStorage == 'en_US' || localeFromPhysicalStorage == 'zh_CN')) {
      if (theDefaultLocale != localeFromPhysicalStorage) {
        theDefaultLocale = localeFromPhysicalStorage;

        // let main page refresh to pick up the language change for navigation bar items
        final BottomNavigationBar navigationBar = globalKeyNav.currentWidget;
        navigationBar.onTap(0);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // do here so that it'll refresh the lessonspage to reflect the lesson completed status from storage.
    // also away from the main thread I think.
    // do it only once
    screenWidth = Utility.getScreenWidth(context);

    // make sure it picks up the right locale
    _dropdownCourseMenuItems = buildDropdownCourseMenuItems(courseMenuList);
//    _selectedCourseMenu = _dropdownCourseMenuItems[0].value;

    handleStorage();

    return Scaffold
      (
      appBar: AppBar
        (
        title: Text(getString(10)/*"Hanzishu Lessons"*/), // "Lessons Page"
      ),
      body: Center
        (
        child: getCoursePage(),
      ),
    );
  }

  Widget getCoursePage() {
    if (_selectedCourseMenu.id == 1) {
      return getHanzishuLessons();
    }
    else if (_selectedCourseMenu.id == 2) {
      return getPaintIndex(context, SoundCategory.intro);
    }
    else if (_selectedCourseMenu.id == 3) {
      return getPaintIndex(context, SoundCategory.erGe);
    }
    else if (_selectedCourseMenu.id == 4) {
      return getPaintIndex(context, SoundCategory.tongYao);
    }
    else if (_selectedCourseMenu.id == 5) {
      return getPaintIndex(context, SoundCategory.tongHua);
    }
  }

  Widget getHanzishuLessons() {
    return ListView.builder(
        itemCount/*itemExtent*/: lessons.length,
        itemBuilder/*IndexedWidgetBuilder*/: (BuildContext context, int index) {
          int lessonCount = 1;

          // assume last row has one item
          if (index == lessons.length - 1) {
            lessonCount = 1;  // have to specify the number of last row
          }
          else if (index < lessons.length - 1) {
            lessonCount = lessons[index + 1] - lessons[index];
          }

          int level = 1;
          //if (index == 0 || index == 4 || index == 8 || index == 11 || index == 14 || index == 18 || index == 21 || index == 24 || index == 27 || index == 30 || index == 34) {
          if (index == 0 || index == 6 || index == 10 || index == 13 || index == 16 || index == 20 || index == 23 || index == 26 || index == 30 || index == 33) {

            if (index == 0) {level = 1;}
            else if (index == 6) { level = 2;}
            else if (index == 10) { level = 3;}
            else if (index == 13) { level = 4;}
            else if (index == 16) { level = 5;}
            else if (index == 20) { level = 6;}
            else if (index == 23) { level = 7;}
            else if (index == 26) { level = 8;}
            else if (index == 30) { level = 9;}
            else if (index == 33) { level = 10;}
            //else if (index == 34) { level = 10;}
            //return getLevel(context, level);
            return getButtonRowWithLevelBegin(context, lessons[index], lessonCount, level);
          }
          else {
            return getButtonRow(context, lessons[index], lessonCount);
          }
        }
    );
  }

  // not use for now
  Widget getADivider(int lessonNumber) {
    if (lessonNumber == 1) {
    return Container(width: 0.0, height: 0.0);
    }
    else {
      return Divider(color: Colors.black);
    }
  }

  List<DropdownMenuItem<CourseMenu>> buildDropdownCourseMenuItems(List courseMenuList) {
    List<DropdownMenuItem<CourseMenu>> items = List();
    for (CourseMenu courseMenu in courseMenuList) {
      items.add(
        DropdownMenuItem(
          value: courseMenu,
          child: Text(getString(courseMenu.stringId)),
        ),
      );
    }
    return items;
  }

  Widget getButtonRowWithLevelBegin(BuildContext context, int lessonNumber, int lessonCount, int level) {
    return Column(
      children: <Widget>[
        //getADivider(lessonNumber),
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget> [
              getCourseType(context, level),
              //SizedBox(width: 30, height: 0),
              Text(
                getString(9)/*"Unit"*/ + " " + '$level' + ": " + getString(BaseLevelDescriptionStringID + level)/*theLevelList[level].description*/,
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 16.0),
              ),
              //SizedBox(width: 30, height: 0),
              //getSpaceAsNeeded(level),
              getLanguageSwitchButtonAsNeeded(level),
              //
            ]
          ),
        ),
        Divider(color: Colors.black),
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: getRowSections(context, lessonNumber, lessonCount),
          ),
          padding: EdgeInsets.all(20),
        ),
      ]
    );
  }

  Widget getLanguageSwitchButtonAsNeeded(int level) {
    if (level != 1) {
      return SizedBox(width: 0, height: 0);
    }

    return TextButton(
      style: TextButton.styleFrom(
        textStyle: TextStyle(fontSize: 16.0),
      ),
      onPressed: () {
        setState(() {
          currentLocale = changeTheDefaultLocale();
          _dropdownCourseMenuItems = buildDropdownCourseMenuItems(courseMenuList);
        });
      },
      child: Text(getOppositeDefaultLocale(), /*English/中文*/
          style: TextStyle(color: Colors.blue)),
    );
  }

  String changeTheDefaultLocale() {
    if (theDefaultLocale == "en_US") {
      theDefaultLocale = "zh_CN";
    }
    else if (theDefaultLocale == "zh_CN") {
      theDefaultLocale = "en_US";
    }

    theStorageHandler.setLanguage(theDefaultLocale);
    theStorageHandler.SaveToFile();

    // let main page refresh to pick up the language change for navigation bar items
    final BottomNavigationBar navigationBar = globalKeyNav.currentWidget;
    navigationBar.onTap(0);

    return theDefaultLocale;
  }

  String getOppositeDefaultLocale() {
    int idForLanguageTypeString = 378; /*English/中文*/
    // according to theDefaultLocale
    String localString = "";

    switch (theDefaultLocale) {
      case "en_US":
        {
          localString = theString_zh_CN[idForLanguageTypeString].str; // theString_en_US[id].str;
        }
        break;
      case "zh_CN":
        {
          localString = theString_en_US[idForLanguageTypeString].str; // theString_zh_CN[id].str;
        }
        break;
      default:
        {
        }
        break;
    }

    return localString;
  }

  Widget getSpaceAsNeeded(int level) {
    if (level != 1) {
      return SizedBox(width: 0, height: 0);
    }

    return SizedBox(width: 60, height: 0);
  }

  Widget getButtonRow(BuildContext context, int lessonNumber, int lessonCount) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: getRowSections(context, lessonNumber, lessonCount),
      ),
      padding: EdgeInsets.all(20),
    );
  }

  List<Widget> getRowSections(BuildContext context, int lessonNumber, int lessonCount) {
    List<Widget> sections = [];
    var realNumber = lessonNumber;
    //var modNumber = realNumber % 10;
    var path = "assets/lessons/L" + realNumber.toString() + ".png";
    //if (modNumber == 9) {
    //  path = "assets/IMG_6606.PNG";
    //}
    sections.add(Container(child: /*OpenHelper.*/getImageButton(context, realNumber, path/*charactertree.png*/, LessonSection.None, true, 110, 110)));

    if (lessonCount >= 2) {
      realNumber++;
      //modNumber = realNumber % 10;
      var path = "assets/lessons/L" + realNumber.toString() + ".png";
      //if (modNumber == 9) {
      //  path = "assets/IMG_6606.PNG";
      //}
      sections.add(Container(child: /*OpenHelper.*/getImageButton(context, realNumber, path/*conversations.png*/, LessonSection.None, true, 110, 110)));

      if (lessonCount >= 3) {
        realNumber++;
        //modNumber = realNumber % 10;
        var path = "assets/lessons/L" + realNumber.toString() + ".png";
        //if (modNumber == 9) {
        //  path = "assets/IMG_6606.PNG";
        //}
        sections.add(Container(child: /*OpenHelper.*/getImageButton(context, realNumber,  path/*charactertree.png*/, LessonSection.None, true, 110, 110)));
      }
    }

    return sections;
  }

  _getRequests() async {
    if (theHasNewlyCompletedLesson) {
      setState(() {
        // force refresh to pick up the completed icon for the lesson
        this.newFinishedLessons += 1;
      });

      theHasNewlyCompletedLesson = false;
    }
  }

  openPage(BuildContext context, int lessonId) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => LessonPage(lessonId: lessonId))).then((val)=>{_getRequests()});
  }

  Widget getImageButton(BuildContext context, int lessonNumber, String imagePath, LessonSection lessonSection, bool isLesson, double xSize, double ySize) {
    //var lesson = theLessonManager.getLesson(lessonNumber);
    //String lessonOrSectionName = "";
      //lessonOrSectionName = lesson.titleTranslation;

      return
        InkWell(
          child: Column(
              children: [
                Ink.image(
                  image: AssetImage(imagePath),
                  width: xSize,
                  height: ySize,
                ),
                Row(
                    children: [
                      Text(
                        lessonNumber.toString() + ". " + getString(BaseLessonTitleTranslationStringID + lessonNumber), //lessonOrSectionName, //lesson.titleTranslation, //"Hello",
                        style: TextStyle(fontSize: 14.0, fontFamily: "Raleway"),
                      ),
                      OpenHelper.getCompletedImage(lessonNumber),
                    ]
                ),
              ]
          ),

          onTap: () => openPage(context, lessonNumber),
        );
    }

  Widget getCourseType(BuildContext context, int level) {
      if (currentSoundCategory == SoundCategory.hanzishuLessons && level > 1) {
        return SizedBox(width: 0, height: 0);
      }

      return DropdownButton(
        value: _selectedCourseMenu,
        items: _dropdownCourseMenuItems,
        onChanged: onChangeDropdownCourseItem,
      );
  }

  onChangeDropdownCourseItem(CourseMenu selectedCourseMenu) {
    setState(() {
      _dropdownCourseMenuItems = buildDropdownCourseMenuItems(courseMenuList);
      _selectedCourseMenu = selectedCourseMenu;
    });
  }

  Widget getPaintIndex(BuildContext context, SoundCategory soundCategory) {
    currentSoundCategory = soundCategory;
    var count = 26; // one extra for pulldown menu
    var courseType;

    if (soundCategory == SoundCategory.intro) {
      count = 3; // where 1 is the temp number for intro buttons, will be 2
      courseType = 2;
    }
    else if (soundCategory == SoundCategory.erGe) {
      courseType = 3;
    }
    else if (soundCategory == SoundCategory.tongYao) {
      courseType = 4;
    }
    else if (soundCategory == SoundCategory.tongHua) {
      courseType = 5;
    }

    return ListView.builder(
        shrinkWrap: true,
        itemCount/*itemExtent*/: count,
        itemBuilder/*IndexedWidgetBuilder*/: (BuildContext context, int index) {
          if (index == 0) {
            return getCourseType(context, courseType); // level
          }
          else {
            return getSoundButtonRow(context, index);
          }
        }
    );
  }

  Widget getSoundButtonRow(BuildContext context, int index) {
    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: getPaintRowSections(context, index),
      ),
      padding: EdgeInsets.all(20),
    );
  }

  List<Widget> getPaintRowSections(BuildContext context, int index) {
    List<Widget> sections = [];

    var path;
    var indexBase;

    if (SoundCategory.intro == currentSoundCategory) {
      if (index == 1) {
        path = "assets/paintx/x1_1.png";
      }
      else if (index == 2) {
        path = "assets/paintx/x2_56.png";
      }
      indexBase = index - 1;
    }
    if (SoundCategory.erGe == currentSoundCategory) {
      path = "assets/lessons/L58.png";
      indexBase = (index - 1) * 4;
    }
    else if (SoundCategory.tongYao == currentSoundCategory) {
      path = "assets/lessons/L59.png";
      indexBase = (index - 1) * 4;
    }
    else if (SoundCategory.tongHua == currentSoundCategory) {
      path = "assets/lessons/L60.png";
      indexBase = (index - 1) * 4;
    }

    sections.add(Container(child: getPaintImageButton(context, indexBase + 1, path, 60, 60)));
    if (SoundCategory.intro != currentSoundCategory) {
      sections.add(Container(
          child: getPaintImageButton(context, indexBase + 2, path, 60, 60)));
      sections.add(Container(
          child: getPaintImageButton(context, indexBase + 3, path, 60, 60)));
      sections.add(Container(
          child: getPaintImageButton(context, indexBase + 4, path, 60, 60)));
    }

    return sections;
  }

  Widget getPaintImageButton(BuildContext context, int lessonNumber, String imagePath, double xSize, double ySize) {
    return InkWell(
        child: Column(
            children: [
              Ink.image(
                image: AssetImage(imagePath),
                width: xSize,
                height: ySize,
              ),
              Text(
                lessonNumber.toString(),
                style: TextStyle(fontSize: 14.0, fontFamily: "Raleway"),
              ),
            ]
        ),

        onTap: () {
          setState(() {
            Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => PaintSoundPage(currentSoundCategory, lessonNumber)));
          });
        }

    );
  }
}