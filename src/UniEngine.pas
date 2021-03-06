unit UniEngine;

interface

Uses SysUtils, Classes, ContNrs, Dialogs, XMLDoc, XMLIntf, xmldom, ActiveX, ShlObj, Graphics, Variants;


// default score. 0=absolute worst, 5=absolute best.
const DEFAULT_SCORE = 2.5;
const MAX_SOCIAL_CLASS = 3;
const SOCIAL_LOWER_CLASS  = 0;
const SOCIAL_MIDDLE_CLASS = 1;
const SOCIAL_UPPER_CLASS  = 2;

const SIZE_HAMLET      = 10;
const SIZE_TOWN        = 25;
const SIZE_CITY        = 80;
const SIZE_CITADEL     = 160;

const NAME_NONE     = -1;
const NAME_MALE     = 0;
const NAME_FEMALE   = 1;
const NAME_LASTNAME = 2;
const NAME_TOWN     = 3;
const NAME_START    = 0;
const NAME_MIDDLE   = 1;
const NAME_END      = 2;

const SOCIAL_CLASS_DEFAULT_SCORE : array[0..2] of Real =  ( 1, 2.5, 4);

// Maximum character age
const DEFAULT_MAX_AGE = 80;

resourcestring
  BENEFIT_HEALTHCARE = 'healthcare';
  BENEFIT_EDUCATION  = 'education';
  BENEFIT_CRIME      = 'crime';
  BENEFIT_EMPLOYMENT = 'employment';
  BENEFIT_PAY        = 'pay';
  BENEFIT_FOOD       = 'food';

  raceFile           = 'data\races.xml';
  occupationFile     = 'data\industries.xml';
  quirkFile          = 'data\quirks.xml';
  personalityFile    = 'data\personality.xml';
  citySizeFile       = 'data\citysizes.xml';
  specialFile        = 'data\specials.xml';

  ErrorLoadingDataFiles = 'Error loading one or more required data files';

  SOCIAL_LOWER_CLASS_NAME  = 'Lower Class';
  SOCIAL_MIDDLE_CLASS_NAME = 'Middle Class';
  SOCIAL_UPPER_CLASS_NAME  = 'Upper Class';

Type
  TSocialClass   = Class;
  TCity          = Class;
  TIndustry      = Class;
  TCitizen       = Class;
  TEvent         = Class;
  TRace          = Class;
  TEventTemplate = Class;

  TRelationshipKind = ( relNone, relParent, relChild, relFriend, relEnemy,
                        relInLove,relMarried, relSibling, relHalfSibling );
TJob = Class
Private
//  TODO : registreer een practitioners entry per city, zodat we MinimumPerCity en NeededPerCitizen kunnen aanpassen. ook een afwijkende factor neerzetten zodat niet ieder dorp hetzelfde is samengesteld.
  fIndustry         : TIndustry;
  fName             : String;
Public
  Property Name : String read fName write fname;
  Property Industry : TIndustry read fIndustry;
  Constructor Create(Industry : TIndustry);
  Destructor Destroy; override;
End;


TCitySize = Class
  NotableCitizens : Integer; // Citizens to generate
  Citizens        : Integer; // Total citizens
  Name            : String;
End;

TCitySizeFlags = Set of ( CsCreateIfMissing );

TCitySizeList = Class
Private
  fList           : Tobjectlist;
  Function getCitySize(Index : Integer) : TCitySize;
Public
  Function getByName(Name : String; Flags : TCitySizeFlags) : TCitySize;
  Function getBySize(Size : Integer) : TCitySize;
  Property Items[Index : Integer] : TCitySize read getCitySize; default;
  Function Count : Integer;
  Constructor Create;
  Destructor Destroy; override;
  Procedure LoadFromXML(Filename : String);
End;

TJobList = Class
Private
  fList            : TObjectlist;
  Function getJob(Index : Integer) : TJob;
Public
  Property Items[Index : Integer] : TJob read getJob; default;
  Procedure add(Value : TJob);
  Procedure Clear;
  Function Count : Integer;
  Constructor Create;
  Destructor Destroy; override;
End;

// Number of practitioners of a certain industry in a certain city.
TPractitioners = Class
Private
  fCity          : TCity;
  fPractitioners : Integer;
Public
  Constructor Create(City : TCity);
  Destructor Destroy; override;
  Property Practitioners : Integer read fPractitioners write fPractitioners;
  Property City          : TCity read fCity;
End;

TPractitionerFlags = Set of ( PfCreateIfMissing );

TPractitionerList = Class
Private
  fList : TObjectlist;
  Function getPractitioner(Index : Integer) : TPractitioners;
Public
  Function getPractitionerByCity(City : TCity; Flags :TPractitionerFlags) : TPractitioners;
  Property Items[Index : Integer] : TPractitioners read getPractitioner; default;
  Procedure add(Value : TPractitioners);
  Procedure Clear;
  Function Count : Integer;
  Constructor Create;
  Destructor Destroy; override;
End;

TIndustry = Class
Private
  fName             : String;
  fNeededPerCitizen : Real;
  fMinimumPerCity   : Real;
  fOccupationList   : TJobList;
  fPractitionerList : TPractitionerList;
  fBadge            : String;
Public
  Property Name  : String read fName write fName;
  // extra badge displayed for all members of this type.
  Property Badge : string read fBadge write fBadge;
  Property NeededPerCitizen : real read fNeededPerCitizen write fNeededPerCitizen;
  Property MinimumPerCity   : Real read fMinimumPerCity   write fMinimumPerCity;
  Property Occupations : TJobList read fOccupationList;
  Procedure RemovePractitioner(Citizen : TCitizen);
  Procedure AddPractitioner(Citizen : TCitizen);
  // Returns a positive number if practitioners are required, and a negative number if there are too many.
  Function PractitionersRequired(City : TCity) : Integer;
  // Returns the maximum practitioners of this industry in the specified city.
  // More than one practitioner 
  Function MaxPractitioners(City : TCity) : Integer;
  Function Practitioners(City : TCity) : Integer;
  Constructor Create;
  Destructor Destroy; override;
End;

TIndustryList = Class
Private
  fList : TObjectlist;
  Function getIndustry(Index : Integer) : TIndustry;
Public
  Property Items[Index : Integer] : TIndustry read getIndustry; default;
  Procedure add(Value : TIndustry);
  Procedure Clear;
  Function Count : Integer;
  Constructor Create;
  Destructor Destroy; override;
  Procedure LoadFromXML(Filename : String);
  Function attemptFindJob(City : TCity; Citizen : TCitizen) : TJob;
End;

TRelationship = Class
Private
  fTarget : TCitizen;
  fKind   : TRelationshipKind;
Public
  Function kindAsString : String;
  Constructor Create(Target : TCitizen);
  Destructor Destroy; override;
  Property Target : TCitizen read fTarget;
  Property Kind   : TRelationshipKind read fKind write fKind;
End;

TRelationshipFlags = Set of ( RfCreateIfMissing );

TRelationshipList = Class
Private
  fList : TObjectlist;
  Function getRelationship(Index : Integer) : TRelationship;
Public
  Function getRelationshipByCitizen(Citizen : TCitizen; Flags : TRelationshipFlags=[]) : TRelationship;
  Property Items[Index : Integer] : TRelationship read getRelationship; default;
  Procedure add(Value : TRelationship);
  Procedure Clear;
  Function Count : Integer;
  Constructor Create;
  Destructor Destroy; override;
  Function getMother : TCitizen;
  Function getFather : TCitizen;
End;

TFamily = Class
Private
  fLastName  : String;
  fRace      : TRace;
  fColor     : TColor;
Public
  Constructor Create(Race : TRace);
  Destructor Destroy; override;
Published
  Property Race     : TRace read fRace write fRace;
  Property Lastname : String read fLastname write fLastname;
  // background color for cells
  Property Color    : TColor read fCOlor write fColor;
  // spawns a first ancestor;
  function spawnAncestor(BirthCity : TCity) : TCitizen;
End;

TFamilyList = Class
Private
  fList : TObjectlist;
  Function getFamily(Index : Integer) : TFamily;
Public
  Function byName(Name : String ) : TFamily;  
  Procedure uniqueRandomLastname(Family : TFamily);
  Property Items[Index : Integer] : TFamily read getFamily; default;
  Procedure add(Value : TFamily);
  Procedure Clear;
  Function Count : Integer;
  Constructor Create;
  Destructor Destroy; override;
End;

TRace = Class
Private
  fName         : String;
  fAdultAge     : Integer;
  fMiddleAge    : Integer;
  fOldAge       : Integer;
  fVenerableAge : Integer;
  fMaxAge       : Integer;
  fNamingParts  : Array[0..3,0..2] of TStringList; // [male/female/lastname/townname, start/middle/end]
  fSuddenDeathPercentage  : Real;
  fBirthPercentage        : Real;
  fNormalNumberKids : Integer;
Public
  // add part of a name to our name generation lists.
  Procedure AddNamePart(NameType : Integer; NodeName : String; NodeValue : String);
  function randomName(NameType : Integer) : String;
  Constructor Create;
  Destructor Destroy; override;
  // Normal number of kids. when this amount is reached, births decrease.
  Property NormalNumberKids : Integer read fNormalNumberKids write fNormalNumberKids;
  Property AdultAge     : Integer read fAdultAge write fAdultAge;
  // year at which race becomes middle aged
  Property MiddleAge    : Integer read fMiddleAge write fMiddleAge;
  // year at which race becomes old
  Property OldAge       : Integer read fOldAge write fOldAge;
  // year at which age becomes venerable
  Property VenerableAge : Integer read fVenerableAge write fVenerableAge;
  // maximum race age
  Property SuddenDeathPercentage : Real read fSuddenDeathPercentage write fSuddenDeathPercentage;
  Property BirthPercentage       : Real read fBirthPercentage write fBirthPercentage;
  Property MaxAge       : Integer read fMaxage write fMaxAge;
  Property Name         : String  read fName write fName;
End;

TRaceList = Class
Private
  fList : TObjectlist;
  Function getRace(Index : Integer) : TRace;
Public
  Function getByName(Name : String) : TRace;
  Property Items[Index : Integer] : TRace read getRace; default;
  Procedure add(Value : TRace);
  Procedure Clear;
  Function Count : Integer;
  Constructor Create;
  Destructor Destroy; override;
  Procedure LoadFromXML(Filename : String);
End;

TQuirkList = Class
Private
  fList : TStringlist;
  Function getQuirk(Index : Integer) : String;
Public
  Property Items[Index : Integer] : String read getQuirk; default;
  Procedure Clear;
  Function Count : Integer;
  Constructor Create;
  Destructor Destroy; override;
  Procedure LoadFromXML(Filename : String);
End;

TSpecialList = Class
Private
  fList : TStringlist;
  Function getItem(Index : Integer) : String;
Public
  Property Items[Index : Integer] : String read getItem; default;
  Procedure Clear;
  Function Count : Integer;
  Constructor Create;
  Destructor Destroy; override;
  Procedure LoadFromXML(Filename : String);
End;

TPersonalityList = Class
Private
  fList : TStringlist;
  Function getItem(Index : Integer) : String;
Public
  Property Items[Index : Integer] : String read getItem; default;
  Procedure Clear;
  Function Count : Integer;
  Constructor Create;
  Destructor Destroy; override;
  Procedure LoadFromXML(Filename : String);
End;

// Special date unit for keeping time.
TEraDate = Class
Private
  fEpoch : Integer;   // number of years since creation.
Public
  Function asString : String;
  Function yearsAgo : String;
  Property Epoch : Integer read fEpoch write fEpoch;
  Procedure Assign(Source : TEraDate);
  Procedure Clear;
  Procedure AddYears(Years : Integer);
  Function hasPassed(yearOffset : Integer=0) : Boolean;
End;

// an event in a citizens life.
// some examples:
//   Imprisonment, released from prison, death (murdered), death (executed),
//   death (old age), death (disease), birth, immigration, emigration,
//   Social (First encounter), Social (Verbal Combat), Social (Physical Combat),
//   Social (Murdered Person), Social (stole from Person), Social (General Positive),
//   Social (Mourning Death), Social (Birth of Child), Social (Helped by),
//   Social (Helped Person), Begin Job, Leave Job, Begin Education, Abort Education
//   Finish Education, Become Sick, Become Cured, Shift in SocialClass.
TEvent = Class
Private
    fTitle       : String;
    fDate        : TEraDate;
//    fParticipant : TCitizen; // Participant to the event, if any.
Public
  Property Title    : String read fTitle write fTitle;
  Property Date     : TEraDate read fDate;
  Constructor Create(EventTemplate : TEventTemplate);
  Destructor Destroy; override;
End;

TEventList = Class
Private
  fList : TObjectlist;
  Function getEvent(Index : Integer) : TEvent;
Public
  Property Items[Index : Integer] : TEvent read getEvent; default;
  Procedure add(Value : TEvent);
  Procedure Clear;
  Function Count : Integer;
  Constructor Create;
  Destructor Destroy; override;
End;

TEventTemplate  = Class
Public
    function asString(Event : TEvent) : String; virtual;
    function getTitle : String; virtual;
    Constructor Create;
    Destructor Destroy; Override;
    Property Title : String read getTitle;
    Procedure Execute(Target : TCitizen); virtual;
    // override with true if it should be applied on dead characters
    function performOnDead : Boolean; virtual;
End;

TEventTemplateList = Class
Private
  fList : TObjectlist;
  Function getEventTemplate(Index : Integer) : TEventTemplate;
Public
  Property Items[Index : Integer] : TEventTemplate read getEventTemplate; default;
  Procedure add(Value : TEventTemplate);
  Procedure Clear;
  Function Count : Integer;
  Constructor Create;
  Destructor Destroy; override;
End;


// A star score of 0 to 5, 0 being worst, 5 being best possible.
// healthcare 0: diseases run rampage 5: best healthcare possible
// education  0: no chance of any education 5: high chance of high level education
// crime      0: crime goes unpunished. 5: crime is always punished.
// employment 0: hardly any jobs available. 5: everyone has a job
// pay        0: jobs pay hardly anything. 5: jobs give high profit.
// food       0: hardly any food is available 5: loads of food is available.
TScore   = Class
Private
  fValue : Real;
Public
  // @SEEALSO TBenefits
  Procedure Combine(Personal, Environmental : TScore);
  Constructor Create;
Published
  Property Value : Real read fValue write fValue;
  Function asString : String;
End;

// Benefits a citizen or social class might enjoy.
TBenefits = Class
Private
  fStringList      : TStringList;
  Function getScoreByName(BenefitIdentifier : String) : TScore;
  Function getScore(Index : Integer) : TScore;
Public
  Property ItemsByName[BenefitIdentifier : String] : TScore read getScoreByName; default;
  Property Items[Index : Integer] : TScore read getScore;
  Function Count : Integer;
  Procedure Clear;
  Function BenefitIdentifier(Index : Integer) : String;
Published
  // Fills this TBefinits with the adjusted benefits of living with the specified
  // Environmental benefits with the specified personal benefits.
  Procedure Combine(Personal, Environmental : TBenefits);
  Constructor Create;
  Destructor Destroy; override;
End;

// CcfBirth : Citizens creation indicates birth
TCitizenCreationFlags = set of ( CcfBirth );

// CsDeceased : Citizen has deceased, no longer partakes in ageing proces.
TCitizenStateFlags    = set of ( CsDeceased );

TAgeCategory          = ( AcChild, AcAdult, AcMiddleAged, AcOld, AcVenerable );

TGender               = ( GeMale, GeFemale  );
TAlignment            = ( AlGood, AlNeutral, AlEvil);

TCitizen = Class
Private
{  fPersonalBenefits  : TBenefits;
  fFinalBenefits     : TBenefits;}
  fSocialClassIndex  : Integer;
  fCity              : TCity;
  fQuirkList         : TStringList;
  fSpecial          : String;
  fBirthFamily       : TFamily;
  fMarriedIntoFamily : TFamily;
  fEventList         : TEventList;
  fBirth             : TEraDate;
  fDeath             : TEraDate;
  fYearsLived        : Integer;
  fPersonality       : String;
  fJob               : TJob;
  fOldJob            : TJob;
  fFlags             : TCitizenStateFlags;
  fRace              : TRace;
  fAgeCategory       : TAgeCategory;
  fAlignment         : TAlignment;
  fFirstName         : String;
  fGeneration        : Integer;
  fGender            : TGender;
  fRelationshipList  : TRelationshipList;
  Function getSocialClass : TSocialClass;
  procedure setCity(Value : TCity);
  procedure setSocialClassIndex(Value : Integer);
  Procedure SetAgeCategory(Value : TAgeCategory);
  // initialize birth;
  Procedure Birth;
  Procedure secureMate;
  // returns TRUE if has a willing partner (in love or married).
  Function BreedingPartner : TCitizen;
  Function getDead : Boolean;
  Procedure setDead(Value : Boolean);
  Procedure setJOb(Value : TJob);
  procedure SecureJob;
  Procedure Retire;
Protected
  fCacheKidsCounter : Integer;
Public
  Function jobName : String;
  Function Rating : Integer; 
  // Spawn a being of this race
  Procedure giveBirth;
  Function fullName(Observer : TCitizen=nil) : String;
  Function nickName : String;
  // Percentage chance to give birth per year. Usually 0 for males.
  Function BirthChance : Real;
Published
  Procedure RandomizePersonality;  
  Function ageYears : Integer;
  // if citizen is married into a family, that becomes her main family.
  Function mainFamily : TFamily;
  Function Badge : String;
  // Current state in life, excluding city benefits.
  Property Special         : String read fSpecial write fSpecial;
  Property Quirks           : TStringList read fQuirkList;
  Property Personality      : String read fPersonality;
  Property Alignment        : TAlignment read fAlignment write fAlignment;
  Property Generation       : Integer read fGeneration write fGeneration;
  Property Relations        : TRelationshipList read fRelationshipList;
  Property FirstName        : String read fFirstName write fFirstName;
{  Property PersonalBenefits : TBenefits read fPersonalBenefits;
  Property FinalBenefits    : TBenefits read fFinalBenefits;}
  Property BirthFamily      : TFamily read fBirthFamily write fBirthFamily;
  Property MarriedIntoFamily : TFamily read fMarriedIntoFamily write fMarriedIntoFamily;
  Property SocialClass      : TSocialClass read getSocialClass;
  Property SocialClassIndex : Integer read FSocialClassIndex write SetSocialClassIndex;
  Property City             : TCity read fCity write SetCity;
  Property Job              : TJob  read fJob write SetJOb;
  Property Events           : TEventList read fEventList;
  // The date this citizen has been born.
  Property BirthDate        : TEraDate read fBirth;
  // The date this citizen is intended to die. (life expectancy)
  Property DeathDate        : TEraDate read fDeath;
  // Recalculate everything that needs to be recalculated
  Property Race             : TRace read fRace write fRace;
  Property AgeCategory      : TAgeCategory read fAgeCategory write SetAgeCategory;
  Property Gender           : TGender read fGender write fGender;
  Function  GenerationAsString : String;
  Property isDead           : Boolean read getDead write setDead;
  Procedure Refresh;
  Constructor Create(Family : TFamily; BirthCity : TCity; Flags : TCitizenCreationFlags);
  Destructor Destroy; override;
  // pick someone we might encounter randomly. people who live in the same city
  // have a larger chance of visiting.
  Function getRandomEncounter : TCitizen;
  Function findPotentialMate : TCitizen;
  // Randomly meet someone, which might cause events.
  Procedure RandomMeetAndGreet;


  // age this citizen one year, triggering new events.
  Procedure Age;
End;

TWorldCitizenList = Class
Private
  fList : TObjectlist;
  Function getCitizen(Index : Integer) : TCitizen;
Public
  Property Items[Index : Integer] : TCitizen read getCitizen; default;
  Procedure add(Value : TCitizen);
  Procedure Clear;
  Function Count : Integer;
  Constructor Create;
  Destructor Destroy; override;
  Procedure AgeAll; // age all citizens one year, triggering new events.
  Procedure GlobalEvent(Event : TEventTemplate);
End;

TSocialClass = Class
Private
  fEnvironmentalBenefits : TBenefits;
Published
  // How this social class benefits its members.
  Property EnvironmentalBenefits : TBenefits read fEnvironmentalBenefits;
  Constructor Create;
  Destructor Destroy; override;
End;

TCity = Class
Private
  fName : String;
  fDesiredCitizens : Integer;
  fCitizens        : Integer;
  fColor           : TColor;
  fMainRace        : TRace;

  fFamilySpawnChance : Real;
  fJobless           : Boolean;

  fSocialClass : Array[0..MAX_SOCIAL_CLASS-1] of TSocialClass;
  Function getSocialClass(Index : Integer) : TSocialClass;
Public
  Property SocialClass[Index : Integer] : TSocialClass read getSocialClass;
  Constructor Create;
  Destructor Destroy; override;
  // Factor in growth based on how far we are from DesiredCitizens
  Function GrowthFactor : Real;
  Procedure Age;
  Procedure spawnRandomFamily;
Published
  // Yearly chance of a new family being spawned here.
  // (Used to populate spawning towns)
  Property FamilySpawnChance : Real read fFamilySpawnChance write fFamilySpawnChance;
  Property MainRace : TRace read fMainRace write fMainRace;
  Property Jobless : Boolean read fJobless write fJobless;
  Property Name : String read fName write fName;
  Property DesiredCitizens : Integer read fDesiredCitizens write fDesiredCitizens;
  Property Citizens : Integer read fCitizens write fCitizens;
  Property Color : TColor read fColor;
End;

TCityList = Class
Private
  fList : TObjectlist;
  Function getCity(Index : Integer) : TCity;
Public
  Property Items[Index : Integer] : TCity read getCity; default;
  Procedure add(Value : TCity);
  Procedure Clear;
  Function Count : Integer;
  Constructor Create;
  Destructor Destroy; override;
  Procedure AgeAll;
  // Finds a job in a different city. ExternalCity is set to the job location, if found.
  Function attemptFindJobEverywhere(Citizen : TCitizen; Var ExternalCity : TCity) : TJob;
End;


Type
TEngine = Class
Private
  fToday             : TEraDate;
  fQuirkList         : TQuirkList;
  fCityList          : TCityList;
  fCitizenList       : TWorldCitizenList;
  fPersonalityList   : TPersonalityList;
  fEventTemplateList : TEventTemplateList;
  fRaceList          : TRaceList;
  fFamilyList        : TFamilyList;
  fIndustryList      : TIndustryList;
  fCitySizelist      : TCitySizeList;
  fSpecialList       : TSpecialList;
Published
  Property Races    : TRaceList read fRaceList;
  Property Families : TFamilyList read fFamilyList;
  Property Cities   : TCityList read fCityList;
  Property Citizens : TWorldCitizenList read fCitizenList;
  Property Quirks   : TQuirkList read fQuirkList;
  // Events that are possible.
  Property Events   : TEventTemplateList read fEventTemplateList;
  Property Today    : TEraDate read fToday;
  Property Industries : TIndustryList read fIndustryList;
  Property Personalities : TPersonalityList read fPersonalityList;
  Property CitySizes : TCitySizeList read fCitySizeList;
  Property Specials : TSpecialList read fSpecialList;
  Procedure LoadFromDisk;
  Procedure Age;
  Procedure Clear;
  Constructor Create;
  Destructor Destroy; override;
End;

Var Engine : TEngine;

implementation

Uses UniEventTemplates;


Function RandomPercentage : Real;
Begin
  Result := Random(1000000) * 0.0001;
End;


Function TScore.asString : String;
Begin
  Result := FloatToStr(Value);
End;

Constructor TScore.Create;
Begin
  Inherited;
  Value := DEFAULT_SCORE;
End;

Procedure TScore.Combine(Personal, Environmental : TScore);
Begin
  Value := (Personal.Value + Environmental.Value) / 2;
End;


Procedure TBenefits.Combine(Personal, Environmental : TBenefits);
Var I : Integer;
    BenefitIdentifier : String;
Begin
  For I := 0 To Personal.Count-1 Do Begin
      BenefitIdentifier := Personal.BenefitIdentifier(I);
      ItemsByName[BenefitIdentifier].Combine(
          Personal.ItemsByName[BenefitIdentifier],
          Environmental.ItemsByName[BenefitIdentifier]);
  End;

  // ok, I realise this might run some calculations twice, but at least we get
  // them all and I save some time coding a mutually exclusive list.
  For I := 0 To Environmental.Count-1 Do Begin
      BenefitIdentifier := Environmental.BenefitIdentifier(I);
      ItemsByName[BenefitIdentifier].Combine(
          Personal.ItemsByName[BenefitIdentifier],
          Environmental.ItemsByName[BenefitIdentifier]);
  End;
End;

Constructor TBenefits.Create;
Begin
  Inherited;
  fStringList      := TStringList.Create;
End;

Function TBenefits.Count : Integer;
Begin
  Result := fStringList.Count;
End;

Procedure TBenefits.Clear;
Var I : Integer;
Begin
  For I := Count-1 DownTo 0 Do Begin
    fStringList.Objects[I].Free;
  End;
  fStringList.Clear;
End;

Function TBenefits.BenefitIdentifier(Index : Integer) : String;
Begin
  Result := fStringList[Index];
End;

Function TBenefits.getScore(Index : Integer) : TScore;
Begin
  Result := fStringList.Objects[Index] as TScore;
End;

Function TBenefits.getScoreByName(BenefitIdentifier : String) : TScore;
Var Index : Integer;
Const NOT_FOUND=-1;
Begin
  Index := fStringList.IndexOf(BenefitIdentifier);
  if Index=NOT_FOUND Then Begin
    Result := TScore.Create;
    fStringList.AddObject(BenefitIdentifier,Result);
    Exit;
  End;
  Result := fStringList.Objects[Index] as TScore;
End;


Destructor TBenefits.Destroy;
Begin
  Clear;
  FreeAndNil(fStringList);
  Inherited;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

// Recalculate everything that needs to be recalculated
Procedure TCitizen.Refresh;
{Var SocialClass : TSocialClass;}
Begin
{  fFinalBenefits.Clear;}
{  SocialClass := getSocialClass;
  if Assigned(SocialClass) Then Begin
    fFinalBenefits.Combine(PersonalBenefits,SocialClass.EnvironmentalBenefits);
  End;}
End;

Procedure TCitizen.Birth;
Var Birth : TEventBirth;
Begin
    Assert(Race<>nil);
    Birth := TEventBirth.Create;
    Try
      Birth.Execute(self);
      BirthDate.Assign(Engine.Today);
      DeathDate.Assign(Engine.Today);
      DeathDate.AddYears(Race.MaxAge);
    Finally
      Birth.Free;
    End;
End;

Function TCitizen.Badge : String;
Begin
 Result := '';
 If fSpecial<>'' Then Result := '!';
 If Assigned(Job) Then
    Result := Result + Job.Industry.Badge;
 If fSpecial<>'' Then Begin
   If (Result <> '') and (Result<>'!') Then Result := Result + ',';
  Result := Result + fSpecial;
 End;
End;

Function TCitizen.ageYears : Integer;
Begin
  Result := fYearsLived;
{  if CsDeceased in Flags THen
    Result := fDeath.Epoch - fBirth.Epoch
  Else
    Result := Engine.Today.Epoch - fBirth.Epoch;}
End;

Function TCitizen.nickName : String;
Begin
   if AgeCategory = AcOld Then Begin
     Result := 'old ' + personality + ' '+FirstName;
   End Else Begin
     Result := FirstName + ' the ' + personality + ' ';
     if Job<>nil Then Result := Result + Job.Name
     Else if fOldJob<>nil Then Result := Result + fOldJob.Name;
   End;
End;

Function TCitizen.fullName(Observer : TCitizen) : String;
Begin
  if Assigned(fBirthFamily) and ((Observer=nil) or (mainFamily <> Observer.mainFamily)) Then
    Result := FirstName + ' ' + BirthFamily.LastName
  Else
    Result := FirstName;

  If (Observer<>nil) and (Observer.City <> Observer.City) Then Result := Result + ' of '+City.Name; 
End;

Function TCitizen.GenerationAsString : String;
Begin
  if Generation<=1 Then
    Result := '1st'
  else if Generation=2 Then
    Result := '2nd'
  else if Generation=3 Then
    Result := '3rd'
  else Result := IntToStr(Generation)+'rd';
End;

Procedure TCitizen.giveBirth;
Var Child : TCitizen;
    relationship : TRelationship;
    EventGiveBirth : TEventGiveBirth;
    Partner : TCitizen;
    ChildFamily : TFamily;
    ChildGeneration : Integer;
    WitnessBirth : TWitnessBirth;
Begin
  Partner := BreedingPartner;

  if Assigned(Partner) and (Partner.Gender = GeMale) Then Begin
    // there is a partner and he/she is male, take his or her family name and generation.
    ChildFamily     := Partner.MainFamily;
    ChildGeneration := Partner.Generation + 1;
  End else Begin
    ChildFamily     := MainFamily;
    ChildGeneration := Generation + 1;
  End;

  Child := TCitizen.Create(ChildFamily, City, [CcfBirth]);
  Child.Generation := ChildGeneration;

  relationship := Child.Relations.getRelationshipByCitizen(self, [RfCreateIfMissing]);
  relationship.kind := relParent;
  relationship := Relations.getRelationshipByCitizen(child, [RfCreateIfMissing]);
  relationship.kind := relChild;

  EventGiveBirth := TEventGiveBirth.Create;
  Try
    EventGiveBirth.Child := Child;
    EventGiveBirth.Execute(self);
  Finally
    EventGiveBirth.Free;
  End;

  Inc(fCacheKidsCounter);
  Partner := BreedingPartner;
  if Assigned(Partner) Then Begin
     Inc(Partner.fCacheKidsCounter);
     relationship := Child.Relations.getRelationshipByCitizen(Partner, [RfCreateIfMissing]);
     relationship.kind := relParent;
     relationship := Partner.Relations.getRelationshipByCitizen(child, [RfCreateIfMissing]);
     relationship.kind := relChild;
  End;

  WitnessBirth := TWitnessBirth.Create;
  Try
    WitnessBirth.BirthOf := Child;
    WitnessBirth.AddParent(Partner);
    WitnessBirth.AddParent(self);
    Engine.Citizens.GlobalEvent(WitnessBirth);
  Finally
    WitnessBirth.Free;
  End;

End;

Procedure TCitizen.secureMate;
Var Mate : TCitizen;
    MyOpinion : TRelationship;
    OtherOpinion : TRelationship;
    Event : TSocialEvent;
Begin
  Mate := findPotentialMate;

{  relInLove,relMarried}

  if Assigned(Mate) Then Begin

      MyOpinion    := Relations.getRelationshipByCitizen(Mate,[RfCreateIfMissing]);
      OtherOpinion := Mate.Relations.getRelationshipByCitizen(self,[RfCreateIfMissing]);

      Case MyOpinion.Kind of
           relInLove,
                       // we already have a relation, do nothing!
           relMarried : Begin Exit; End;
           relFriend  :
                     Begin
                       Event := TEventMarried.Create;
                       MyOpinion.Kind    := relMarried;
                       OtherOpinion.Kind := relMarried;
                       Try
                          Event.Other := Mate;
                          Event.Execute(self);
                          Event.Other := self;
                          Event.Execute(Mate);
                       Finally
                           Event.Free;
                       End;

                       If random(2) < 1 Then
                         Mate.City := City
                       Else
                         City := Mate.City;

                        // small chance to start a new family for diversity sake.
                       if RandomPercentage < 10 Then Begin
                          Mate.MarriedIntoFamily := TFamily.Create(Mate.Race);
                          MarriedIntoFamily      := Mate.MarriedIntoFamily;
                       End;

                       // Mirror Family
                       if Gender = GeFemale Then
                         MarriedIntoFamily := Mate.BirthFamily
                       Else
                         Mate.MarriedIntoFamily := BirthFamily;
                     End;
           Else Raise Exception.Create('huh');
      End;
  End;
End;

Procedure TCitizen.RandomMeetAndGreet;
Var Meet : TCitizen;
    MyOpinion : TRelationship;
    OtherOpinion : TRelationship;
    Event : TSocialEvent;
    HappyEncounterPercentage : Integer;
Begin
  Meet := getRandomEncounter;
  if Assigned(Meet) Then Begin
      MyOpinion    := Relations.getRelationshipByCitizen(Meet,[RfCreateIfMissing]);
      OtherOpinion := Meet.Relations.getRelationshipByCitizen(self,[RfCreateIfMissing]);

      if MyOpinion.Kind = relNone Then Begin

          HappyEncounterPercentage := 50;

          // Good meets good, evil meets evil
          If Alignment = Meet.Alignment Then Inc(HappyEncounterPercentage,25);

          // Good meets evil, evil meets good
          If (Alignment <> Meet.Alignment) and
             (Alignment <> alNeutral ) and
             (Meet.Alignment <> alNeutral ) Then Dec(HappyEncounterPercentage,25);

          if HappyEncounterPercentage > 95 Then HappyEncounterPercentage := 95;
          if HappyEncounterPercentage <  5 Then HappyEncounterPercentage :=  5;

          If RandomPercentage < HappyEncounterPercentage Then Begin
            Event := TEventMadeFriend.Create;
            MyOpinion.Kind := relFriend;
            OtherOpinion.Kind := relFriend;
          End else begin
            Event := TEventMadeEnemy.Create;
            MyOpinion.Kind := relEnemy;
            OtherOpinion.Kind := relEnemy;
          End;

          Try
            Event.Other := meet;
            Event.Execute(self);
            Event.Other := self;
            Event.Execute(meet);
          Finally
            Event.Free;
          End;
      End;
  End;
End;


Function TCitizen.findPotentialMate : TCitizen;
Var
  Count : Integer;
  Index : Integer;
  fTmpCitizenList : TObjectList;
  Relationship : TRelationship;
  Other : TCitizen;
Begin
  Result := nil;
  Count := Relations.Count;
  fTmpCitizenList := TObjectlist.Create;
  Try
    fTmpCitizenList.OwnsObjects := False;

    For Index := 0 To Count-1 Do Begin
      Relationship := Relations[Index];
      Other        := Relationship.fTarget;
      
      // find someone alive, opposite gender, different family, same race, same age category.
      if (Other.BirthFamily <> BirthFamily)
         and (Other.AgeCategory = AgeCategory)
         and (Other.Race = Race)
         and (Other.Gender <> Gender)
         and (not Other.isDead) Then Begin

         Case Relationship.Kind of
             // we already have a mate, so lets check him or her!
             relInLove,
             relMarried : Begin Result := Other; Exit; End;
             relFriend  : Begin fTmpCitizenList.Add(Other); End;
          End;
      End;
    End;

    if fTmpCitizenList.Count > 0 Then
      Result := fTmpCitizenList[Random(fTmpCitizenList.Count)] as TCitizen;
  Finally
    fTmpCitizenList.Free;
  End;
End;

Function TCitizen.getRandomEncounter : TCitizen;
Var
  Count : Integer;
  Index : Integer;
  fTmpCitizenList : TObjectList;
Begin
  Result := nil;
  Count := Engine.Citizens.Count;
  fTmpCitizenList := TObjectlist.Create;
  Try
    fTmpCitizenList.OwnsObjects := False;
    For Index := 0 To Count -1 Do Begin
      if (Engine.Citizens[Index].BirthFamily <> BirthFamily)
         and (not Engine.Citizens[Index].isDead) Then Begin

        If (Engine.Citizens[Index].City = City) Then Begin
            fTmpCitizenList.Add(Engine.Citizens[Index]);
        End Else Begin
            // Chance to meet people from different cities.
            if RandomPercentage < 5 Then
              fTmpCitizenList.Add(Engine.Citizens[Index]);
        End;
      End;
    End;

    if fTmpCitizenList.Count > 0 Then
      Result := fTmpCitizenList[Random(fTmpCitizenList.Count)] as TCitizen;
  Finally
    fTmpCitizenList.Free;
  End;
End;


Function TCitizen.mainFamily : TFamily;
Begin
  if MarriedIntoFamily<>nil Then
    Result := MarriedIntOFamily
  Else
    Result := BirthFamily;
End;

Function TCitizen.getDead : Boolean;
Begin
  Result := (CsDeceased in fFlags);
End;

Procedure TCitizen.setDead(Value : Boolean);
Var
  WitnessDeath : TWitnessDeath;
Begin
  if (Value = True) and not (CsDeceased in fFlags) Then begin
    fFlags := fFlags + [CsDeceased];
    WitnessDeath := TWitnessDeath.Create;
    Try
      WitnessDeath.DeathOf := self;
      Engine.Citizens.GlobalEvent(WitnessDeath);
    Finally
      WitnessDeath.Free;
    End;
    if Assigned(fJob)  then fJob.Industry.RemovePractitioner(self);
    if Assigned(fCity) then fCity.Citizens    := fCity.Citizens-1;
  End;
  if value = False Then fFlags := fFlags - [CsDeceased];
end;


Constructor TCitizen.Create(Family : TFamily; BirthCity : TCity; Flags : TCitizenCreationFlags);
Begin
  Inherited Create;

  fQuirkList       := TStringList.Create;
  fOldJob          := nil;

  RandomizePersonality;
  
  if Random(2) < 1 Then Begin
    fGender            := GeMale;
    fFirstName         := Family.Race.randomName(NAME_MALE);
  End Else Begin
    fGender            := GeFemale;
    fFirstName         := Family.Race.randomName(NAME_FEMALE);
  End;
  fYearsLived        := 0;
  fBirthFamily       := Family;
  fRace              := Family.Race;
  fMarriedIntoFamily := nil;
  fRelationshipList  := TRelationshipList.Create;
{  fPersonalBenefits  := TBenefits.Create;
  fFinalBenefits     := TBenefits.Create;}
  fCacheKidsCounter  := 0;
  fSocialClassIndex  := SOCIAL_MIDDLE_CLASS;

  // run it past setCity
  fCity := nil;
  City               := BirthCity;

  fEventList         := TEventList.Create;
  fBirth             := TEraDate.Create;
  fDeath             := TEraDate.Create;
  fGeneration        := 1;
  fAgeCategory       := AcChild;
  if CcfBirth in Flags Then Birth;
  Engine.Citizens.add(self);
End;

Procedure TCitizen.RandomizePersonality;
Var Count : Integer;
    I     : Integer;
Begin
  fAlignment         := AlNeutral;
  If RandomPercentage < 35 Then fAlignment := AlGood;
  If RandomPercentage < 25 Then fAlignment := AlEvil;

  fQuirkList.Clear;
  Count := 1;
  if RandomPercentage < 25 Then Inc(Count);
  if RandomPercentage < 15 Then Inc(Count);
  For I := 0 To Count-1 do fQuirkList.Add(Engine.Quirks[Random(Engine.Quirks.Count)]);

  fPersonality     := Engine.Personalities[Random(Engine.Personalities.Count)];

  fSpecial := '';
  if RandomPercentage < 1 Then fSpecial := Engine.Specials[Random(Engine.Specials.Count)];
End;

Destructor TCitizen.Destroy;
Begin
  City := nil;
  Job  := nil;
  FreeAndNil(fQuirkList);
  FreeAndNil(fBirth);
  FreeAndNil(fDeath);
  FreeAndNil(fEventList);
{  FreeAndNil(0fPersonalBenefits);
  FreeAndNil(fFinalBenefits);}
  FreeAndNil(fRelationshipList);
  Inherited;
End;

Function TCitizen.jobName : String;
Begin
  if Assigned(Job) Then Begin
    if AgeCategory=AcChild Then
      Result := 'Apprentice '+Job.name
    Else
      Result := Job.name
  End Else if Assigned(fOldJob) Then
    Result := 'retired '+fOldJob.name
  Else Result := '';
End;

Function TCitizen.BreedingPartner : TCitizen;
Var Mate : TCitizen;
    MyOpinion : TRelationship;
Begin
  Mate := findPotentialMate;
  Result := nil;
  if Assigned(Mate) Then Begin
      MyOpinion    := Relations.getRelationshipByCitizen(Mate,[RfCreateIfMissing]);
      If MyOpinion.Kind in [RelInLove,RelMarried] Then Result := Mate;
  End;
End;

procedure TCitizen.setCity(Value : TCity);
Var Emigrate : TEventEmigrate;
Begin
  if fCity <> Value Then Begin
    if (fCity <> nil) and (Value <> nil) Then Begin
      Emigrate := TEventEmigrate.Create;
      Try
        Emigrate.toCity := Value;
        Emigrate.Execute(self);
      Finally
        Emigrate.Free;
      End;
    End;
    Job := nil;
    if Assigned(fCity) and (not isDead) then fCity.Citizens := fCity.Citizens-1;
    fCity := Value;
    if Assigned(fCity) then fCity.Citizens := fCity.Citizens+1;
    Refresh;
  End;
End;


procedure TCitizen.SecureJob;
Var JobInOthercity : TJob;
    ExternalJobCity   : TCity;
Begin
  if (fJob = nil) and (RandomPercentage < 75) and (AgeCategory < AcOld) Then Begin

    If (AgeCategory <= AcChild) and ((RandomPercentage < 95) or (fYearsLived<6)) Then Exit;

    Job := Engine.Industries.attemptFindJob(City, self);
    If job = nil Then Begin
      JobInOtherCity := Engine.Cities.attemptFindJobEverywhere(self, ExternalJobCity);
      If Assigned(JobInOtherCity) Then Begin
         // lets move!
         City := ExternalJobCity;
         Job  := JobInOtherCity;
      End;
    End;
  End;
End;

procedure TCitizen.setJob(Value : TJob);
Var Working : TEventStartedWorking;
Begin
  if fJob <> Value Then Begin
    if (Value <> nil) Then Begin
      Working := TEventStartedWorking.Create;
      Try
        Working.Job := Value;
        Working.Execute(self);
      Finally
        Working.Free;
      End;
    End;
    if Assigned(fJob) and (not isDead) then fJob.Industry.RemovePractitioner(self);
    fOldJob := fJob;
    fJob := Value;
    if Assigned(fJob) then fJob.Industry.AddPractitioner(self);
    Refresh;
  End;
End;

procedure TCitizen.setSocialClassIndex(Value : Integer);
Begin
  if fSocialClassIndex <> Value Then Begin
    fSocialClassIndex := Value;
    Refresh;
  End;
End;

Function TCitizen.Rating : Integer;
Begin
  if fSpecial<>'' Then
    Result := 5
  Else
  Case AgeCategory of
     AcAdult         : Result := 1+relations.Count div 3;
     AcMiddleAged    : Result := (relations.Count div 5);
     AcOld           : Result := relations.Count div 8;
     AcVenerable     : Result := relations.Count div 16;
     Else Result := 0;
  End;

End;

Function TCitizen.getSocialClass : TSocialClass;
Begin
  if assigned(fCity) Then Begin
    Result := fCity.SocialClass[SocialClassIndex];
  End Else Result := nil;
End;

Procedure TCitizen.Retire;
Var EventRetire : TEventRetire;
Begin
  if Assigned(fJob) Then Begin
    EventRetire := TEventRetire.Create;
    Try
      EventRetire.Execute(self);
    Finally
      EventRetire.Free;
    End;
    Job := nil;
  End;
End;

Procedure TCitizen.SetAgeCategory(Value : TAgeCategory);
Var Event : TEventTemplate;
Begin
  if fAgeCategory <> Value Then Begin
    fAgeCategory := Value;
    Case AgeCategory of
      AcVenerable : Event := TEventReachedVenerableAge.Create;
      AcOld       : Event := TEventReachedOldAge.Create;
      AcMiddleAged : Event := TEventReachedMiddleAge.Create;
      AcAdult    : Event := TEventReachedAdultAge.Create;
      Else Exit;
    End;
    Try
      Event.Execute(self);
    Finally
      Event.Free;
    End;
  End;
End;

Function TCitizen.BirthChance : Real;
Begin
    Result := 0;

    If (BreedingPartner=nil) or (Gender <> GeFemale) Then Exit; 

    Case AgeCategory of
        AcAdult      : Result := Race.BirthPercentage;
        AcMiddleAged : Result := Race.BirthPercentage / 10;
    End;

    If fCacheKidsCounter > Race.NormalNumberKids Then Begin
          // if we are 1 kid over normal, birth chance 1/2th.
          // if we are 2 kids over normal, birth chance becomes 1/3rd
          // if we are 4 kids over normal, birth chance becomes 1/4th, etc.
          Result := Result / (fCacheKidsCounter-Race.NormalNumberKids+1);
    End;

    // We make sure our cities grow to the desired size!
    Result := Result * City.GrowthFactor;
End;


Procedure TCitizen.Age;
Var Death : TEventDeath;
Begin
  // Age this character

  // We're deceased, nothing happens on our account.
  if CsDeceased in fFlags THen Exit;

  Inc(fYearsLived);

  // Lets check if we should've died already. small chance to avoid death each year.
  if (fDeath.HasPassed) and (RandomPercentage > 50) Then Begin
    Death := TEventNaturalDeath.Create;
    Try
      Death.Execute(self);
    Finally
      Death.Free;
    End;
    // Character dies! oh noes!
    Exit;
  End;

  If RandomPercentage < Race.SuddenDeathPercentage Then Begin
    // Sudden death! eep!
    Death := TEventSuddenDeath.Create;
    Try
      Death.Execute(self);
    Finally
      Death.Free;
    End;
    Exit;
  End;

  If (BirthChance > 0) and (RandomPercentage < BirthChance) Then giveBirth;

  if Assigned(Race) Then Begin

    if (AgeCategory < AcVenerable)  and fBirth.hasPassed(race.VenerableAge) Then Begin
        AgeCategory := AcVenerable;
        if (fJob<>nil) and (RandomPercentage<25) then retire;
    End else if (AgeCategory < AcOld)   and fBirth.hasPassed(race.OldAge)       Then Begin
        AgeCategory := AcOld;
        if (fJob<>nil) and (RandomPercentage<75) then retire;
    End else if (AgeCategory < AcMiddleAged) and fBirth.hasPassed(race.fMiddleAge)   Then Begin
        AgeCategory := AcMiddleAged;
        // Find an MiddleAged friend, if any.
        if RandomPercentage < 25 Then RandomMeetAndGreet;
    End else if (AgeCategory < AcAdult) and fBirth.hasPassed(race.fAdultAge)     Then Begin
        AgeCategory := AcAdult;
        // Find an Adult friend, if any.
        if RandomPercentage < 50 Then RandomMeetAndGreet;
    End;
  End;

  // meet some people
  if RandomPercentage < 5 Then Begin
    RandomMeetAndGreet;
  End;

  SecureJob;
  SecureMate;
// Recalculate all benefits.
  Refresh;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Function TCity.getSocialClass(Index : Integer) : TSocialClass;
Begin
  Assert((Index>=0) and (Index<=MAX_SOCIAL_CLASS));
  Result := fSocialClass[Index];
End;


Function TCity.GrowthFactor : Real;
Begin
  if Citizens >= DesiredCitizens Then GrowthFactor := 0.5
  Else if Citizens <  DesiredCitizens-100  Then GrowthFactor := 1.5
  Else if Citizens <  DesiredCitizens-50   Then GrowthFactor := 1.2
  Else GrowthFactor := 1;
End;

Procedure TCity.spawnRandomFamily;
Var Family : TFamily;
    Mother,Father : Tcitizen;
Begin
 if fMainRace = nil Then fMainRace := Engine.Races[0];
 Family        := TFamily.Create(fMainRace);;

 Mother        := Family.spawnAncestor(self);
 Mother.Gender := GeMale;
 Father        := Family.spawnAncestor(self);
 Father.Gender := GeFemale;
 Father.Relations.getRelationshipByCitizen(Mother, [RfCreateIfMissing]).Kind := relMarried;
 Mother.Relations.getRelationshipByCitizen(Father, [RfCreateIfMissing]).Kind := relMarried;
End;

Procedure TCity.Age;
Begin
  if ( fFamilySpawnChance > 0 ) and (RandomPercentage < fFamilySpawnChance) Then Begin
    spawnRandomFamily;
  End;
End;


Constructor TCity.Create;
Var I : Integer;
Begin
  Inherited;
  fFamilySpawnChance := 0;
  fJobless           := False;
  fDesiredCitizens   := 0;
  fCitizens          := 0;
  fColor := $EEEEEE + (random(16)) + (random(16)*$100) + (random(16)*$10000);
  For I := 0 To MAX_SOCIAL_CLASS -1 Do Begin
      fSocialClass[I] := TSocialClass.Create;
      fSocialClass[I].EnvironmentalBenefits[BENEFIT_HEALTHCARE].Value := SOCIAL_CLASS_DEFAULT_SCORE[I];
      fSocialClass[I].EnvironmentalBenefits[BENEFIT_EDUCATION].Value := SOCIAL_CLASS_DEFAULT_SCORE[I];
      fSocialClass[I].EnvironmentalBenefits[BENEFIT_CRIME].Value := SOCIAL_CLASS_DEFAULT_SCORE[I];
      fSocialClass[I].EnvironmentalBenefits[BENEFIT_EMPLOYMENT].Value := SOCIAL_CLASS_DEFAULT_SCORE[I];
      fSocialClass[I].EnvironmentalBenefits[BENEFIT_PAY].Value := SOCIAL_CLASS_DEFAULT_SCORE[I];
      fSocialClass[I].EnvironmentalBenefits[BENEFIT_FOOD].Value := SOCIAL_CLASS_DEFAULT_SCORE[I];
  End;
End;

Destructor TCity.Destroy;
Var I : Integer;
Begin
  For I := 0 To MAX_SOCIAL_CLASS -1 Do
      FreeAndNil(fSocialClass[I]);
  Inherited;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Function TWorldCitizenList.getCitizen(Index : Integer) : TCitizen;
Begin
  Result := fList.Items[Index] as TCitizen;
End;

Procedure TWorldCitizenList.AgeAll; // age all citizens one year, triggering new events.
Var CitizenCount : Integer;
    I : Integer;
Begin
  CitizenCount := Count;
  For I := CitizenCount-1 Downto 0 Do
      Items[I].Age;
End;


Procedure TWorldCitizenList.add(Value : TCitizen);
Begin
  fList.Add(Value);
End;

Procedure TWorldCitizenList.Clear;
Begin
  fList.Clear;
End;

Procedure TWorldCitizenList.GlobalEvent(Event : TEventTemplate);
Var CitizenCount : Integer;
    I : Integer;
Begin
  CitizenCount := Count;
  For I := CitizenCount-1 Downto 0 Do Begin
    if (not Items[I].isDead) or Event.performOnDead() Then
      Event.Execute(Items[I]);
  End;
End;

Function TWorldCitizenList.Count : Integer;
Begin
  result := fList.Count;
End;

Constructor TWorldCitizenList.Create;
Begin
  Inherited;
  fList := TObjectList.Create;
  fList.OwnsObjects := True;
End;

Destructor TWorldCitizenList.Destroy;
Begin
  FreeAndNil(fList);
  Inherited;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Function TCityList.attemptFindJobEverywhere(Citizen : TCitizen; Var ExternalCity : TCity) : TJob;
Var i :Integer;
    JobList  : TObjectList;
    CityList : TObjectList;
    JobIndex : Integer;
    JobInOtherCity : TJob;
Begin
  Result := nil; ExternalCity := nil;
  JobList  := TObjectList.Create; JobList.OwnsObjects := False;
  CityList := TObjectList.Create; CityList.OwnsObjects := False;
  Try
    For I := 0 To Engine.Cities.Count-1 Do Begin

      // do not calculate a city thats shrinking.
      If Engine.Cities[I].GrowthFactor < 0 Then Continue;

      JobInOtherCity := Engine.Industries.attemptFindJob(Engine.Cities[I], Citizen);
      if Assigned(JobInOtherCity) Then Begin
        JobList.Add(JobInOtherCity);
        CityList.Add(Engine.Cities[I]);
      End;
    End;
    If JobList.Count > 0 Then Begin
      JobIndex     := Random(JobList.Count);
      Result       := JobList[JobIndex] as TJob;
      ExternalCity := CityList[JobIndex] as TCity;
    End;
  Finally
    JobList.Free;
    CityList.Free;
  End;
End;

Procedure TCityList.AgeAll; // age all citizens one year, triggering new events.
Var CityCount : Integer;
    I : Integer;
Begin
  CityCount := Count;
  For I := CityCount-1 Downto 0 Do
      Items[I].Age;
End;


Function TCityList.getCity(Index : Integer) : TCity;
Begin
  Result := fList.Items[Index] as TCity;
End;

Procedure TCityList.add(Value : TCity);
Begin
  fList.Add(Value);
End;

Procedure TCityList.Clear;
Begin
  fList.Clear;
End;

Function TCityList.Count : Integer;
Begin
  result := fList.Count;
End;

Constructor TCityList.Create;
Begin
  Inherited;
  fList := TObjectList.Create;
  fList.OwnsObjects := True;
End;

Destructor TCityList.Destroy;
Begin
  Clear;
  FreeAndNil(fList);
  Inherited;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Constructor TEngine.Create;
Begin
  Inherited;
  fCitySizelist := TCitySizeList.Create;
  fCityList     := TCityList.Create;
  fCitizenList  := TWorldCitizenList.Create;
  fToday        := TEraDate.Create;
  fRaceList     := TRaceList.Create;
  fFamilyList   := TFamilyList.Create;
  fIndustryList := TIndustryList.Create;
  fQuirkList    := TQuirkList.Create;
  fPersonalityList := TPersonalityList.Create;
  fSpecialList  := TSpecialList.Create;


  fEventTemplateList := TEventTemplateList.Create;
  fEventTemplateList.Add(TEventTemplate.Create);
End;

Procedure TEngine.LoadFromDisk;
Begin
  Races.LoadFromXML(raceFile);
  Industries.LoadFromXML(occupationFile);
  Quirks.LoadFromXML(quirkFile);
  Personalities.LoadFromXML(personalityFile);
  CitySizes.LoadFromXML(citySizeFile);
  Specials.LoadFromXML(specialFile);
End;

Procedure TEngine.Clear;
Begin
  fToday.Clear;
  fCitizenList.Clear;
  fCityList.Clear;
  fFamilyList.Clear;
End;

Procedure TEngine.Age;
Begin
  fToday.AddYears(1);
  fCityList.AgeAll;
  fCitizenList.AgeAll;
End;

Destructor TEngine.Destroy;
Begin
  FreeAndNil(fSpecialList);
  FreeAndNil(fCitySizelist);
  FreeAndNil(fPersonalityList);
  FreeAndNil(fQuirkList);
  FreeAndNil(fFamilyList);
  FreeAndNil(fRaceList);
  FreeAndNil(ftoday);
  FreeAndNil(fEventTemplateList);
  FreeAndNil(fCitizenList);
  FreeAndNil(fCityList);
  FreeAndNil(fIndustryList);
  Inherited;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Function TEventTemplateList.getEventTemplate(Index : Integer) : TEventTemplate;
Begin
  Result := fList.Items[Index] as TEventTemplate;
End;

Procedure TEventTemplateList.add(Value : TEventTemplate);
Begin
  fList.Add(Value);
End;

Procedure TEventTemplateList.Clear;
Begin
  fList.Clear;
End;

Function TEventTemplateList.Count : Integer;
Begin
  result := fList.Count;
End;

Constructor TEventTemplateList.Create;
Begin
  Inherited;
  fList := TObjectList.Create;
  fList.OwnsObjects := True;
End;

Destructor TEventTemplateList.Destroy;
Begin
  FreeAndNil(fList);
  Inherited;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Function TEventList.getEvent(Index : Integer) : TEvent;
Begin
  Result := fList.Items[Index] as TEvent;
End;

Procedure TEventList.add(Value : TEvent);
Begin
  fList.Add(Value);
End;

Procedure TEventList.Clear;
Begin
  fList.Clear;
End;

Function TEventList.Count : Integer;
Begin
  result := fList.Count;
End;

Constructor TEventList.Create;
Begin
  Inherited;
  fList := TObjectList.Create;
  fList.OwnsObjects := True;
End;

Destructor TEventList.Destroy;
Begin
  FreeAndNil(fList);
  Inherited;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Constructor TEvent.Create(EventTemplate : TEventTemplate);
Begin
  Assert(EventTemplate<>nil);
  Inherited create;
  fDate     := TEraDate.Create;
  fDate.Assign(Engine.Today);
  fTitle    := EventTemplate.asString(self);
End;

Destructor TEvent.Destroy;
Begin
  FreeAndNil(fDate);
  Inherited;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

function TEventTemplate.asString(Event : TEvent) : String;
Begin
  Result := Title;
End;

function TEventTemplate.performOnDead : Boolean;
Begin
  Result := False;
End;

Constructor TEventTemplate.Create;
Begin
  Inherited;
End;

Destructor TEventTemplate.Destroy;
Begin
  Inherited;
End;

function TEventTemplate.getTitle : String;
Begin
  Result := '<untitled>';
End;

Procedure TEventTemplate.Execute(Target : TCitizen);
Begin                                
 Target.Events.add(TEvent.Create(self));
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Procedure TEraDate.Assign(Source : TEraDate);
Begin
  Epoch := Source.Epoch;
End;

Procedure TEraDate.Clear;
Begin
  Epoch := 0;
End;

Function TEraDate.asString : String;
Var EpochR : Real;
Begin
  EpochR := Epoch;
  Result :=Format('%.0n',[EpochR]);
End;

Function TEraDate.yearsAgo : String;
Begin
  Result := IntToStr(Engine.Today.Epoch-Epoch);
End;


Function TEraDate.hasPassed(yearOffset : Integer=0) : Boolean;
Begin
  Result := Epoch+yearOffset <= Engine.Today.Epoch;
End;

Procedure TEraDate.AddYears(Years : Integer);
Begin
  Epoch := Epoch + Years;
End;

Constructor TSocialClass.Create;
Begin
  fEnvironmentalBenefits := TBenefits.Create;
End;

Destructor TSocialClass.Destroy;
Begin
  FreeAndNil(fEnvironmentalBenefits);
  Inherited;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Procedure TRace.AddNamePart(NameType : Integer; NodeName : String; NodeValue : String);
Var Location : Integer;
Begin
  Location := NAME_NONE;
  if NodeName = 'start'  then Location := NAME_START;
  if NodeName = 'middle' then Location := NAME_MIDDLE;
  if NodeName = 'end'    then Location := NAME_END;
  assert(Location<>NAME_NONE);
  fNamingParts[NameType,Location].add(NodeValue);
End;

Constructor TRace.Create;
Var i,j : Integer;
Begin
  Inherited;
  For I := 0 To 3 Do
    For J := 0 To 2 Do fNamingParts[I,J] := TStringList.Create;
End;

Destructor TRace.Destroy;
Var i,j : Integer;
Begin
  For I := 0 To 3 Do
    For J := 0 To 2 Do fNamingParts[I,J].Free;
  Inherited;
End;

function TRace.randomName(NameType : Integer) : String;
{Var MaxParts : Integer;
    I : Integer;}
Begin

 Result := fNamingParts[NameType,NAME_START][Random(fNamingParts[NameType,NAME_START].Count)];
 Result := Result + fNamingParts[NameType,NAME_MIDDLE][Random(fNamingParts[NameType,NAME_MIDDLE].Count)];
 if RandomPercentage < 50 Then
 Result := Result + fNamingParts[NameType,NAME_END][Random(fNamingParts[NameType,NAME_END].Count)];

 {  MaxParts := 2;
  if RandomPercentage < 50 Then MaxParts := MaxParts + 1;
  if RandomPercentage < 2 Then MaxParts := MaxParts + 1;
  if RandomPercentage < 2 Then MaxParts := MaxParts + 1;
  For I := 0 To MaxParts-1 Do
    Result := Result + fLastNameParts[Random(fLastNameParts.Count-1)];       }
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Procedure TRaceList.LoadFromXML(Filename : String);
Var
  entry  : IXMLNode;
  Race   : TRace;
  XML    : IXMLDocument;
  naming : IXMLNode;
  part   : IXMLNode;
begin
  XML := TXMLDocument.Create(FileName);
  XML.Active := True;
  entry      := XML.DocumentElement.ChildNodes.FindNode('race');
  Clear;
  repeat
     Race              := TRace.Create;
     Race.Name         := entry.ChildValues['racename'];
     Race.AdultAge     := entry.ChildValues['adultAge'];
     Race.MiddleAge    := entry.ChildValues['middleAge'];
     Race.OldAge       := entry.ChildValues['oldAge'];
     Race.VenerableAge := entry.ChildValues['venerableAge'];
     Race.MaxAge       := entry.ChildValues['maxAge'];
     Race.SuddenDeathPercentage := entry.ChildValues['suddenDeathPercentage'];
     Race.BirthPercentage       := entry.ChildValues['birthPercentage'];
     Race.NormalNumberKids := entry.ChildValues['normalNumberKids'];

     naming := entry.ChildNodes.FindNode('malename');
     part   := naming.ChildNodes.first;
     while part <> nil do begin
        Race.AddNamePart(NAME_MALE, Part.NodeName, Part.NodeValue);
        part := part.NextSibling;
     end;

     naming := entry.ChildNodes.FindNode('femalename');
     part   := naming.ChildNodes.first;
     while part <> nil do begin
        Race.AddNamePart(NAME_FEMALE,Part.NodeName, Part.NodeValue);
        part := part.NextSibling;
     end;

     naming := entry.ChildNodes.FindNode('lastname');
     part   := naming.ChildNodes.first;
     while part <> nil do begin
        Race.AddNamePart(NAME_LASTNAME,Part.NodeName, Part.NodeValue);
        part := part.NextSibling;
     end;

     naming := entry.ChildNodes.FindNode('townname');
     part   := naming.ChildNodes.first;
     while part <> nil do begin
        Race.AddNamePart(NAME_TOWN, Part.NodeName, Part.NodeValue);
        part := part.NextSibling;
     end;

     Add(Race);
     entry  := entry.NextSibling;
  until entry = nil;
End;

Function TRaceList.getByName(Name : String) : TRace;
VAr I : Integer;
Begin
  Result := nil;
  For I :=0 To Count-1 Do Begin
    if Items[I].Name = NAme Then Begin
      Result := Items[I];
      Exit;
    End;
  End;
End;

Function TRaceList.getRace(Index : Integer) : TRace;
Begin
  Result := fList.Items[Index] as TRace;
End;

Procedure TRaceList.add(Value : TRace);
Begin
  fList.Add(Value);
End;

Procedure TRaceList.Clear;
Begin
  fList.Clear;
End;

Function TRaceList.Count : Integer;
Begin
  result := fList.Count;
End;

Constructor TRaceList.Create;
Begin
  Inherited;
  fList := TObjectList.Create;
  fList.OwnsObjects := True;
End;

Destructor TRaceList.Destroy;
Begin
  FreeAndNil(fList);
  Inherited;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Constructor TRelationship.Create(Target : TCitizen);
Begin
  Inherited Create;
  fKind   := relNone;
  fTarget := Target;
End;

Function   TRelationship.kindAsString : String;
Begin
  case fKind of
    relNone   : Result := 'None';
    relParent  : if (fTarget.gender = GeMale) Then
                     Result := 'Father'
                 Else
                     Result := 'Mother';
    relSibling  : if (fTarget.gender = GeMale) Then
                       Result := 'Brother'
                   Else
                       Result := 'Sister';
    relHalfSibling  : if (fTarget.gender = GeMale) Then
                       Result := 'Half-Brother'
                   Else
                       Result := 'Half-Sister';
    relChild   : Result := 'Child';
    relEnemy   : Result := 'Enemy';
    relFriend  : Result := 'Friend';
    relInLove  : Result := 'Loves';
    relMarried : Result := 'Married';
  End;
End;

Destructor TRelationship.Destroy;
Begin
  Inherited;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Function TRelationshipList.getRelationship(Index : Integer) : TRelationship;
Begin
  Result := fList.Items[Index] as TRelationship;
End;

Procedure TRelationshipList.add(Value : TRelationship);
Begin
  fList.Add(Value);
End;


Function TRelationshipList.getRelationshipByCitizen(Citizen : TCitizen; Flags :TRelationshipFlags) : TRelationship;
Var I : Integer;
Begin
  For I := 0 To Count-1 Do Begin
    if Items[I].Target = Citizen Then Begin Result := Items[I]; Exit; End;
  End;

  If RfCreateIfMissing in Flags Then Begin
    Result := TRelationship.Create(Citizen);
    Add(Result);
  End Else
    Result := nil;
End;

Procedure TRelationshipList.Clear;
Begin
  fList.Clear;
End;

Function TRelationshipList.Count : Integer;
Begin
  result := fList.Count;
End;

Constructor TRelationshipList.Create;
Begin
  Inherited;
  fList := TObjectList.Create;
  fList.OwnsObjects := True;
End;

Destructor TRelationshipList.Destroy;
Begin
  FreeAndNil(fList);
  Inherited;
End;

Function TRelationshipList.getMother : TCitizen;
Var I : Integer;
Begin
  Result := nil;
   For I := 0 To Count-1 Do Begin
     If (Items[I].Kind = RelParent) and (Items[I].Target.Gender = GeFemale) Then Begin
       Result := Items[I].Target;
     End;
   End;
End;

Function TRelationshipList.getFather : TCitizen;
Var I : Integer;
Begin
  Result := nil;
   For I := 0 To Count-1 Do Begin
     If (Items[I].Kind = RelParent) and (Items[I].Target.Gender = GeMale) Then Begin
       Result := Items[I].Target;
     End;
   End;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


Function TFamily.SpawnAncestor(BirthCity : TCity) : TCitizen;
Begin
 Result := TCitizen.Create(self,BirthCity , [CcfBirth]);
End;

Constructor TFamily.Create(Race : TRace);
Begin
  Inherited Create;
  fRace := Race;
  fColor := $EEEEEE + (random(16)) + (random(16)*$100) + (random(16)*$10000);
  if assigned(race) Then Engine.Families.uniqueRandomLastname(self);
  Engine.Families.add(self);
End;

Destructor TFamily.Destroy;
Begin
  Inherited;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


Function TFamilyList.getFamily(Index : Integer) : TFamily;
Begin
  Result := fList.Items[Index] as TFamily;
End;

Procedure TFamilyList.add(Value : TFamily);
Begin
  fList.Add(Value);
End;

Function TFamilyList.byName(Name : String ) : TFamily;
Var I : Integer;
Begin
 For I := 0 To fList.Count-1  Do Begin
  If Items[I].LastName = name then begin
      result := Items[I];
      Exit;
  End;
 End;
 Result := nil;
End;

Procedure TFamilyList.uniqueRandomLastname(Family : TFamily);
var LastName : String;
Begin
  LastName := Family.Race.randomName(NAME_LASTNAME);
  while byName(LastName) <> nil Do LastName := Family.Race.randomName(NAME_LASTNAME);
  Family.LastName := LastName;
End;


Procedure TFamilyList.Clear;
Begin
  fList.Clear;
End;

Function TFamilyList.Count : Integer;
Begin
  result := fList.Count;
End;

Constructor TFamilyList.Create;
Begin
  Inherited;
  fList := TObjectList.Create;
  fList.OwnsObjects := True;
End;

Destructor TFamilyList.Destroy;
Begin
  FreeAndNil(fList);
  Inherited;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Procedure TIndustryList.LoadFromXML(Filename : String);
Var
  entry  : IXMLNode;
  Industry   : TIndustry;
  XML    : IXMLDocument;
  naming : IXMLNode;
  part   : IXMLNode;
  Job : TJob;
  A : Integer;
begin
  XML := TXMLDocument.Create(FileName);
  XML.Active := True;
  entry      := XML.DocumentElement.ChildNodes.FindNode('industry');
  Clear;
  repeat
     Industry                   := TIndustry.Create;
     Industry.Name              := entry.ChildValues['name'];
     Industry.neededPerCitizen  := entry.ChildValues['neededPerCitizen'];
     Industry.MinimumPerCity    := entry.ChildValues['minimumPerCity'];
     If entry.ChildValues['badge'] <> NULL Then
       Industry.Badge             := entry.ChildValues['badge'];
     naming := entry.ChildNodes.FindNode('occupations');
     part   := naming.ChildNodes.FindNode('occupation');
     while part <> nil do begin
        Job := TJob.Create(Industry);
        A := pos('(',Part.NodeVAlue);
        if A > 0 Then
          Job.Name := Copy(Part.NodeVAlue,1,A-1)
        Else
          Job.Name := Part.NodeVAlue;
        part := part.NextSibling;
     end;
     Add(Industry);
     entry  := entry.NextSibling;
  until entry = nil;
End;

Function TIndustryList.getIndustry(Index : Integer) : TIndustry;
Begin
  Result := fList.Items[Index] as TIndustry;
End;

Procedure TIndustryList.add(Value : TIndustry);
Begin
  fList.Add(Value);
End;

Procedure TIndustryList.Clear;
Begin
  fList.Clear;
End;

Function TIndustryList.Count : Integer;
Begin
  result := fList.Count;
End;

Constructor TIndustryList.Create;
Begin
  Inherited;
  fList := TObjectList.Create;
  fList.OwnsObjects := True;
End;

Destructor TIndustryList.Destroy;
Begin
  FreeAndNil(fList);
  Inherited;
End;

Function TIndustryList.attemptFindJob(City : TCity; Citizen : TCitizen) : TJob;
Var IndustrIndex : Integer;
  TmpJobList : TObjectList;
  Jobindex : Integer;
  JobsLeftInCity : Integer;
Begin
  REsult := nil;

  // this city represents an external kingdom.
  if City.Jobless Then Exit;

  TmpJobList := TObjectList.Create;
  TmpJobList.OwnsObjects := False;
  Try
    For IndustrIndex := 0 To Count-1 Do Begin
       JobsLeftInCity := Items[IndustrIndex].PractitionersRequired(Citizen.City);

       If (JobsLeftInCity > 0) Then
       For Jobindex := 0 To Items[IndustrIndex].Occupations.Count-1 Do Begin
           TmpJobList.Add(Items[IndustrIndex].Occupations[JobIndex]);
       End;
    End;

    if TmpJObList.Count > 0 Then
      Result := TmpJobList[Random(TmpJobList.Count)] as TJob;
  Finally
    TmpJobList.Free;
  End;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Function TJobList.getJob(Index : Integer) : TJob;
Begin
  Result := fList.Items[Index] as TJob;
End;

Procedure TJobList.add(Value : TJob);
Begin
  fList.Add(Value);
End;

Procedure TJobList.Clear;
Begin
  fList.Clear;
End;

Function TJobList.Count : Integer;
Begin
  result := fList.Count;
End;

Constructor TJobList.Create;
Begin
  Inherited;
  fList := TObjectList.Create;
  fList.OwnsObjects := True;
End;

Destructor TJobList.Destroy;
Begin
  FreeAndNil(fList);
  Inherited;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Constructor TJob.Create(Industry : TIndustry);
Begin
  Inherited Create;
  fIndustry         := Industry;
  fName             := '';
  Industry.Occupations.Add(self);
End;

Destructor TJob.Destroy;
Begin
  Inherited;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Procedure TIndustry.RemovePractitioner(Citizen : TCitizen);
Var Practitioners : TPractitioners;
Begin
  Practitioners := fPractitionerList.getPractitionerByCity(Citizen.City,[PfCreateIfMissing]);
  Practitioners.Practitioners :=
    Practitioners.Practitioners - 1;
End;

Procedure TIndustry.AddPractitioner(Citizen : TCitizen);
Var Practitioners : TPractitioners;
Begin
  Practitioners := fPractitionerList.getPractitionerByCity(Citizen.City,[PfCreateIfMissing]);
  Practitioners.Practitioners :=
    Practitioners.Practitioners + 1;
End;

Function TIndustry.MaxPractitioners(City : TCity) : Integer;
Var Max : Real;
Begin
  Assert(City<>nil);

  // First calculate the maximum jobs available in a city.
  Max := City.DesiredCitizens * NeededPerCitizen;
  If Max < MinimumPerCity Then Max := MinimumPerCity;

  Result := Round(Max);
End;

Function TIndustry.Practitioners(City : TCity) : Integer;
Begin
  Result := fPractitionerList.getPractitionerByCity(City,[PfCreateIfMissing]).Practitioners;
End;


Function TIndustry.PractitionersRequired(City : TCity) : Integer;
Begin
  Assert(City<>nil); 
  Result := MaxPractitioners(City) - Practitioners(City);
End;

Constructor TIndustry.Create;
Begin
  Inherited;
  fOccupationList   := TJobList.Create;
  fPractitionerList := TPractitionerList.Create;
  fBadge            := '';
  fName             := '';
  fNeededPerCitizen := 0;
  fMinimumPerCity   := 0;
End;

Destructor TIndustry.Destroy;
Begin
  FreeAndNil(fPractitionerList);
  FreeAndNil(fOccupationList);
  Inherited;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


Function TPractitionerList.getPractitioner(Index : Integer) : TPractitioners;
Begin
  Result := fList.Items[Index] as TPractitioners;
End;

Procedure TPractitionerList.add(Value : TPractitioners);
Begin
  fList.Add(Value);
End;

Function TPractitionerList.getPractitionerByCity(City : TCity; Flags :TPractitionerFlags) : TPractitioners;
Var I : Integer;
Begin
  For I := 0 To Count-1 Do Begin
    if Items[I].City = City Then Begin Result := Items[I]; Exit; End;
  End;

  If PfCreateIfMissing in Flags Then Begin
    Result := TPractitioners.Create(City);
    Add(Result);
  End Else
    Result := nil;
End;

Procedure TPractitionerList.Clear;
Begin
  fList.Clear;
End;

Function TPractitionerList.Count : Integer;
Begin
  result := fList.Count;
End;

Constructor TPractitionerList.Create;
Begin
  Inherited;
  fList := TObjectList.Create;
  fList.OwnsObjects := True;
End;

Destructor TPractitionerList.Destroy;
Begin
  FreeAndNil(fList);
  Inherited;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Constructor TPractitioners.Create(City : TCity);
Begin
  Inherited Create;
  fPractitioners := 0;
  fCity          := City;
End;

Destructor TPractitioners.Destroy;
Begin
  Inherited;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Procedure TQuirkList.LoadFromXML(Filename : String);
Var
  entry  : IXMLNode;
  XML    : IXMLDocument;
begin
  XML := TXMLDocument.Create(FileName);
  XML.Active := True;
  entry      := XML.DocumentElement.ChildNodes.FindNode('quirk');
  Clear;
  repeat
     fList.Add(entry.NodeValue);
     entry  := entry.NextSibling;
  until entry = nil;
End;

Function TQuirkList.getQuirk(Index : Integer) : String;
Begin
  Result := fList[Index];
End;

Procedure TQuirkList.Clear;
Begin
  fList.Clear;
End;

Function TQuirkList.Count : Integer;
Begin
  result := fList.Count;
End;

Constructor TQuirkList.Create;
Begin
  Inherited;
  fList := TStringList.Create;
End;

Destructor TQuirkList.Destroy;
Begin
  FreeAndNil(fList);
  Inherited;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Procedure TPersonalityList.LoadFromXML(Filename : String);
Var
  entry  : IXMLNode;
  XML    : IXMLDocument;
begin
  XML := TXMLDocument.Create(FileName);
  XML.Active := True;
  entry      := XML.DocumentElement.ChildNodes.FindNode('personality');
  Clear;
  repeat
     fList.Add(entry.NodeValue);
     entry  := entry.NextSibling;
  until entry = nil;
End;

Function TPersonalityList.getItem(Index : Integer) : String;
Begin
  Result := fList[Index];
End;

Procedure TPersonalityList.Clear;
Begin
  fList.Clear;
End;

Function TPersonalityList.Count : Integer;
Begin
  result := fList.Count;
End;

Constructor TPersonalityList.Create;
Begin
  Inherited;
  fList := TStringList.Create;
End;

Destructor TPersonalityList.Destroy;
Begin
  FreeAndNil(fList);
  Inherited;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

Function TCitySizeList.getCitySize(Index : Integer) : TCitySize;
Begin
  Result := fList[Index] as TCitySize;
End;

Function TCitySizeList.Count : Integer;
Begin
  Result := fList.Count;
End;

Function TCitySizeList.getBySize(Size : Integer) : TCitySize;
Var I : Integer;
Begin
 For I := 0 To Count-1 Do Begin
    If Items[I].NotableCitizens = Size Then Begin
      Result := Items[I];
      Exit;
    End;
 End;
 Result := nil;
End;

Function TCitySizeList.getByName(Name : String; Flags : TCitySizeFlags) : TCitySize;
Var I : Integer;
Begin
 For I := 0 To Count-1 Do Begin
    If Items[I].Name = NAme Then Begin
      Result := Items[I];
      Exit;
    End;
 End;
 Result := nil;
End;

Constructor TCitySizeList.Create;
Begin
  Inherited;
  fList           := Tobjectlist.Create;
  fList.OwnsObjects := True;
End;

Destructor TCitySizeList.Destroy;
Begin
  FreeAndNil(fList);
  Inherited;
End;

Procedure TCitySizeList.LoadFromXML(Filename : String);
Var
  entry  : IXMLNode;
  CitySize : TCitySize;
  XML    : IXMLDocument;
begin
  XML := TXMLDocument.Create(FileName);
  XML.Active := True;
  entry      := XML.DocumentElement.ChildNodes.FindNode('citysize');
  fList.Clear;
  repeat
     CitySize                 := TCitySize.Create;
     CitySize.Name            := entry.ChildValues['name'];
     CitySize.NotableCitizens := entry.ChildValues['notableCitizens'];
     CitySize.Citizens        := entry.ChildValues['citizens'];
     fList.Add(CitySize);
     entry  := entry.NextSibling;
  until entry = nil;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////
////////////////////////////////////////////////////////////////////////////

Procedure TSpecialList.LoadFromXML(Filename : String);
Var
  entry  : IXMLNode;
  XML    : IXMLDocument;
begin
  XML := TXMLDocument.Create(FileName);
  XML.Active := True;
  entry      := XML.DocumentElement.ChildNodes.FindNode('special');
  Clear;
  repeat
     fList.Add(entry.NodeValue);
     entry  := entry.NextSibling;
  until entry = nil;
End;

Function TSpecialList.getItem(Index : Integer) : String;
Begin
  Result := fList[Index];
End;

Procedure TSpecialList.Clear;
Begin
  fList.Clear;
End;

Function TSpecialList.Count : Integer;
Begin
  result := fList.Count;
End;

Constructor TSpecialList.Create;
Begin
  Inherited;
  fList := TStringList.Create;
End;

Destructor TSpecialList.Destroy;
Begin
  FreeAndNil(fList);
  Inherited;
End;

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////


Initialization
 Randomize;
 // CoInitialize is required for XMLDocument
 CoInitialize(nil);
 Engine := TEngine.Create;
 Try
    Engine.LoadFromDisk;
 Except
    on E : Exception do ShowMessage(ErrorLoadingDataFiles+' ('+E.Message+')');
 End;
Finalization
 If assigned(Engine) Then FreeAndNil(Engine);
end.
