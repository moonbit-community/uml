// Official PlantUML theme resources, vendored from .local/plantuml/src/main/resources/themes.
// Theme-specific attribution and license metadata are retained with each entry.
// Keep this data synchronized with the reference checkout; do not hand-edit palette values.

///|
fn builtin_theme_source(name : String) -> String? {
  match name {
    "_none_" => Some(builtin_theme_0)
    "amiga" => Some(builtin_theme_1)
    "aws-orange" => Some(builtin_theme_2)
    "black-knight" => Some(builtin_theme_3)
    "bluegray" => Some(builtin_theme_4)
    "blueprint" => Some(builtin_theme_5)
    "carbon-gray" => Some(builtin_theme_6)
    "cerulean-outline" => Some(builtin_theme_7)
    "cerulean" => Some(builtin_theme_8)
    "cloudscape-design" => Some(builtin_theme_9)
    "crt-amber" => Some(builtin_theme_10)
    "crt-green" => Some(builtin_theme_11)
    "cyborg-outline" => Some(builtin_theme_12)
    "cyborg" => Some(builtin_theme_13)
    "hacker" => Some(builtin_theme_14)
    "lightgray" => Some(builtin_theme_15)
    "mars" => Some(builtin_theme_16)
    "materia-outline" => Some(builtin_theme_17)
    "materia" => Some(builtin_theme_18)
    "metal" => Some(builtin_theme_19)
    "mimeograph" => Some(builtin_theme_20)
    "minty" => Some(builtin_theme_21)
    "mono" => Some(builtin_theme_22)
    "plain" => Some(builtin_theme_23)
    "reddress-darkblue" => Some(builtin_theme_24)
    "reddress-darkgreen" => Some(builtin_theme_25)
    "reddress-darkorange" => Some(builtin_theme_26)
    "reddress-darkred" => Some(builtin_theme_27)
    "reddress-lightblue" => Some(builtin_theme_28)
    "reddress-lightgreen" => Some(builtin_theme_29)
    "reddress-lightorange" => Some(builtin_theme_30)
    "reddress-lightred" => Some(builtin_theme_31)
    "sandstone" => Some(builtin_theme_32)
    "silver" => Some(builtin_theme_33)
    "sketchy-outline" => Some(builtin_theme_34)
    "sketchy" => Some(builtin_theme_35)
    "spacelab-white" => Some(builtin_theme_36)
    "spacelab" => Some(builtin_theme_37)
    "sunlust" => Some(builtin_theme_38)
    "superhero-outline" => Some(builtin_theme_39)
    "superhero" => Some(builtin_theme_40)
    "toy" => Some(builtin_theme_41)
    "united" => Some(builtin_theme_42)
    "vibrant" => Some(builtin_theme_43)
    _ => None
  }
}

///|
// name: _none_
// display_name: None
// description: A no theme named `_none_` (intentionally empty); Especially to have a `no theme` (first or last in alphabetical order) to compare with all the others.
// author: The-Lum
let builtin_theme_0 : String = ""

///|
// name: amiga
// display_name: Amiga Workbench 1.x
// description: A white on blue theme based on Amiga Workbench 1.x
// author: Matthew Leather
// release:
// license:
// version:
// source:
// inspiration: https://en.wikipedia.org/wiki/Workbench_(AmigaOS)#Workbench_1.x
let builtin_theme_1 : String =
  #|
  #|!$THEME = "amiga"
  #|
  #|!$BLACK  = "#000121"
  #|!$BLUE   = "#0B58A8"
  #|!$ORANGE = "#FDA325"
  #|!$RED    = "#DB252B"
  #|!$WHITE  = "#FFFFFF"
  #|
  #|!$BGCOLOR = $BLUE
  #|!$FGCOLOR = $WHITE
  #|
  #|!ifndef $FONT_NAME
  #|  !$FONT_NAME = "Verdana"
  #|!endif
  #|
  #|!ifndef $FONT_NAME_MONOSPACED
  #|  !$FONT_NAME_MONOSPACED = "Courier"
  #|!endif
  #|
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $FGCOLOR
  #|    FontName $FONT_NAME
  #|    HyperLinkColor $ORANGE
  #|    LineColor $FGCOLOR
  #|    LineThickness 1
  #|    Margin 5
  #|  }
  #|  document {
  #|    caption {
  #|      LineThickness 0
  #|    }
  #|    footer {
  #|      LineThickness 0
  #|    }
  #|    header {
  #|      LineThickness 0
  #|    }
  #|    title {
  #|      FontSize 22
  #|      LineThickness 0
  #|    }
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  node {
  #|    MaximumWidth 300
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  participant {
  #|    Margin 5 10
  #|    Padding 5 5
  #|  }
  #|</style>
  #|
  #|skinparam ArrowLollipopColor $FGCOLOR
  #|skinparam BackgroundColor $BGCOLOR
  #|skinparam DefaultFontName $FONT_NAME
  #|skinparam DefaultMonospacedFontName $FONT_NAME_MONOSPACED
  #|skinparam LifelineStrategy nosolid
  #|skinparam SequenceLifeLineBorderColor $FGCOLOR
  #|skinparam Shadowing false
  #|skinparam UseBetaStyle true
  #|
  #|skinparam Activity {
  #|  BackgroundColor $BGCOLOR
  #|  BarColor $FGCOLOR
  #|  BorderColor $FGCOLOR
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Boundary {
  #|  FontColor $FGCOLOR
  #|}
  #|skinparam Box {
  #|  Padding 5
  #|}
  #|skinparam CircledCharacter {
  #|  FontColor $BGCOLOR
  #|  FontName $FONT_NAME_MONOSPACED
  #|  Radius 9
  #|}
  #|skinparam Class {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam ClassAttribute {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam ClassStereotype {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Footer {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Header {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Hyperlink {
  #|  Color $ORANGE
  #|}
  #|skinparam IconPackage {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam IconPrivate {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam IconProtected {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam IconPublic {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam Note {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Object {
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam Package {
  #|  BorderColor $FGCOLOR
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam State {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeA {
  #|  BackgroundColor $FGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeC {
  #|  BackgroundColor $FGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeE {
  #|  BackgroundColor $FGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeI {
  #|  BackgroundColor $FGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeN {
  #|  BackgroundColor $FGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam UseCaseStereoType {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}

///|
// name: aws-orange
// display_name: AWS orange
// description: Theme based off of the colors used by Amazon Web Services
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration:
let builtin_theme_2 : String =
  #|
  #|!$PUML_THEME = "aws-orange"
  #|!$THEME      = "aws-orange"
  #|''
  #|'' User can specify the PUML_BGCOLOR via command line or set this variable before
  #|'' loading this theme file. PUML_BGCOLOR is the background color of the image that is
  #|'' generated by plantuml
  #|''
  #|!if %not(%variable_exists("$PUML_BGCOLOR"))
  #|    !$PUML_BGCOLOR = "transparent"
  #|!endif
  #|''
  #|'' If no gradient is given, default to 20
  #|''
  #|!if %not(%variable_exists("$PUML_GRADIENT"))
  #|    !$PUML_GRADIENT = 20
  #|!endif
  #|''
  #|'' User can specify the PUML_MODE via command line or set this variable before
  #|'' loading this theme file. PUML_MODE is either 'light' PUML_MODE or 'dark' PUML_MODE.
  #|''
  #|!if %not(%variable_exists("$PUML_MODE"))
  #|    !$PUML_MODE = "light"
  #|!endif
  #|''
  #|'' User can specify the PUML_OUTLINE via command line or set this variable before
  #|'' loading this theme file. PUML_OUTLINE is either 'true' or 'false'.
  #|''
  #|!if %not(%variable_exists("$PUML_OUTLINE"))
  #|    !$PUML_OUTLINE = "false"
  #|!endif
  #|''
  #|skinparam BackgroundColor $PUML_BGCOLOR
  #|skinparam useBetaStyle false
  #|''
  #|'' Supplementary Colors
  #|''
  #|!$WHITE      = "#FFF"
  #|!$GRAY_LIGHT = "#222"
  #|!$GRAY       = "#868e96"
  #|!$PRIMARY    = "#EC7211"
  #|!$WARNING    = "#EC7211"
  #|!$LIGHT      = "#abb6c2"
  #|!$DARK       = "#4E5D6C"
  #|''
  #|'' define colors based on PUML_MODE
  #|''
  #|!if ($PUML_MODE == "light")
  #|    !$SECONDARY      = "#eeeeee"
  #|    '' hardcode $SECONDARY_LIGHT since it is so close to white
  #|    !$SECONDARY_LIGHT = "ffffff"
  #|    !$SUCCESS        = "#1D8102"
  #|    !$INFO           = "#0073bb"
  #|    !$DANGER         = "#d13212"
  #|    !$SECONDARY_TEXT = $DARK
  #|    !$FGCOLOR        = $DARK
  #|	!$DIAMOND_BD     = %darken($SECONDARY, $PUML_GRADIENT)
  #|    ''
  #|    '' Assume if the background is transparent, that the
  #|    '' background will be dark for this theme
  #|    ''
  #|    !assume transparent light
  #|!else
  #|    !$SECONDARY      = "#2a2e33"
  #|    !$SECONDARY_LIGHT = %lighten($SECONDARY, $PUML_GRADIENT)
  #|    !$SUCCESS        = "#6aaf35"
  #|    !$INFO           = "#44b9d6"
  #|    !$DANGER         = "#ff5d64"
  #|    !$SECONDARY_TEXT = $WHITE
  #|    !$FGCOLOR        = $WHITE
  #|	!$DIAMOND_BD     = %lighten($SECONDARY, $PUML_GRADIENT)
  #|    ''
  #|    '' Assume if the background is transparent, that the
  #|    '' background will be dark for this theme
  #|    ''
  #|    !assume transparent dark
  #|!endif
  #|''
  #|'' *_DARK = tint (lighter) of the main color
  #|'' *_LIGHT = shade (darker) of the main color
  #|''
  #|!$PRIMARY_DARK    = %darken($PRIMARY, $PUML_GRADIENT)
  #|!$PRIMARY_LIGHT   = %lighten($PRIMARY, $PUML_GRADIENT)
  #|!$SECONDARY_DARK  = %darken($SECONDARY, $PUML_GRADIENT)
  #|!$SUCCESS_DARK    = %darken($SUCCESS, $PUML_GRADIENT)
  #|!$SUCCESS_LIGHT   = %lighten($SUCCESS, $PUML_GRADIENT)
  #|!$INFO_DARK       = %darken($INFO, $PUML_GRADIENT)
  #|!$INFO_LIGHT      = %lighten($INFO, $PUML_GRADIENT)
  #|!$DANGER_DARK     = %darken($DANGER, $PUML_GRADIENT)
  #|!$DANGER_LIGHT    = %lighten($DANGER, $PUML_GRADIENT)
  #|!$WARNING_DARK    = %darken($WARNING, $PUML_GRADIENT)
  #|!$WARNING_LIGHT   = %lighten($WARNING, $PUML_GRADIENT)
  #|!$DARK_DARK       = %darken($DARK, $PUML_GRADIENT)
  #|!$DARK_LIGHT      = %lighten($DARK, $PUML_GRADIENT)
  #|!$LIGHT_DARK      = %darken($LIGHT, $PUML_GRADIENT)
  #|!$LIGHT_LIGHT     = %lighten($LIGHT, $PUML_GRADIENT)
  #|''
  #|'' Set text colors
  #|''
  #|!$INFO_TEXT    = $WHITE
  #|!$SUCCESS_TEXT = $WHITE
  #|!$WARNING_TEXT = $WHITE
  #|!$DANGER_TEXT  = $WHITE
  #|!$PRIMARY_TEXT = $WHITE
  #|!$HEADER_TEXT  = $WHITE
  #|''
  #|!if ($PUML_OUTLINE == "true")
  #|	!$HEADER_TEXT  = $PRIMARY_TEXT
  #|	!$PRIMARY_TEXT = $PRIMARY_LIGHT
  #|	!$INFO_TEXT    = $INFO_LIGHT
  #|	!$WARNING_TEXT = $WARNING_LIGHT
  #|	!$DARK_BG      = $PUML_BGCOLOR
  #|	!$INFO_BG      = $PUML_BGCOLOR
  #|	!$DANGER_BG    = $PUML_BGCOLOR
  #|	!$WARNING_BG   = $PUML_BGCOLOR
  #|	!$SECONDARY_BG = $PUML_BGCOLOR
  #|!else
  #|	!$DARK_BG      = $DARK
  #|	!$INFO_BG      = $INFO
  #|	!$DANGER_BG    = $DANGER
  #|	!$WARNING_BG   = $WARNING
  #|	!$SECONDARY_BG = $SECONDARY
  #|!endif
  #|''
  #|'' Called to make the text in the color of SUCCESS
  #|''
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|''
  #|'' Called to make the text in the color of DANGER
  #|''
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|''
  #|'' Called to make the text in the color of WARNING
  #|''
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|''
  #|'' Called to use the primary color scheme
  #|'' Different colors based on if PUML_OUTLINE
  #|'' is true or not
  #|''
  #|!procedure $primary_scheme()
  #|	!if ($PUML_OUTLINE == "true")
  #|		FontColor $PRIMARY
  #|		BorderColor $PRIMARY
  #|		BackgroundColor $PUML_BGCOLOR
  #|	!else
  #|		FontColor $PRIMARY_TEXT
  #|		BorderColor $PRIMARY
  #|		BackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|	!endif
  #|!endprocedure
  #|''
  #|'' Called to use the secondary color scheme
  #|''
  #|!procedure $secondary_scheme()
  #|	!if ($PUML_OUTLINE == "true")
  #|		FontColor $SECONDARY_DARK
  #|		BorderColor $SECONDARY_DARK
  #|		BackgroundColor $PUML_BGCOLOR
  #|	!else
  #|		FontColor $SECONDARY_TEXT
  #|		BorderColor $SECONDARY_DARK
  #|		BackgroundColor $SECONDARY_LIGHT-$SECONDARY
  #|	!endif
  #|!endprocedure
  #|''
  #|'' HTTP Methods
  #|''
  #|!_POST   = "<color #007a3e>POST</color>"
  #|!_PUT    = "<color #ea7400>PUT</color>"
  #|!_DELETE = "<color #cf2a2a>DELETE</color>"
  #|!_GET    = "<color #009fdb>GET</color>"
  #|!_PATCH  = "<color #b5bd00>PATCH</color>"
  #|!_HEAD   = "<color #9012fe>HEAD</color>"
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName       "Verdana"
  #|skinparam defaultFontSize       12
  #|skinparam dpi                   100
  #|skinparam shadowing             false
  #|skinparam roundcorner           8
  #|skinparam BoxPadding            40
  #|skinparam ArrowColor            $DARK
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_LIGHT
  #|    CBorderColor $SECONDARY_DARK
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|}
  #|
  #|skinparam legend {
  #|    $secondary_scheme()
  #|    BackgroundColor transparent
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|' <style>
  #|' mindmapDiagram {
  #|' 	Padding 15
  #|' 	Margin 10
  #|' 	FontSize 12
  #|' 	FontName Verdana
  #|' 	Shadowing 0.0
  #|' 	LineThickness 1.5
  #|' 	FontColor $PRIMARY_TEXT
  #|' 	LineColor $PRIMARY_DARK
  #|'     node {
  #|' 	    LineColor $PRIMARY
  #|' 	    BackGroundColor $PRIMARY_LIGHT-$PRIMARY
  #|'     }
  #|' }
  #|' </style>
  #|
  #|!startsub activity
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $SECONDARY_BG
  #|  	DiamondBorderColor $DIAMOND_BD
  #|  	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|skinparam actor {
  #|	$primary_scheme()
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|skinparam sequence {
  #|	ArrowThickness 3
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $PRIMARY
  #|	BackgroundColor $PUML_BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $PUML_BGCOLOR
  #|	BoxBorderColor $DARK
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $LIGHT
  #|	LifeLineBorderThickness 2
  #|	LifeLineBackgroundColor $LIGHT_DARK
  #|	''
  #|	GroupBorderColor $DARK
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO
  #|	GroupBackgroundColor $SECONDARY
  #|	GroupBodyBackgroundColor $PUML_BGCOLOR
  #|	GroupHeaderBackgroundColor $PUML_BGCOLOR
  #|	''
  #|	DividerBackgroundColor $DARK
  #|    DividerBorderColor $DARK
  #|    DividerBorderThickness 2
  #|    DividerFontColor $LIGHT
  #|	''
  #|	ReferenceBackgroundColor $PUML_BGCOLOR
  #|	ReferenceBorderColor $DARK
  #|	ReferenceFontColor $DARK
  #|	ReferenceHeaderFontColor $INFO
  #|	ReferenceHeaderBackgroundColor $SECONDARY
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|	StereotypeFontSize 12
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BackgroundColor $PUML_BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|skinparam control {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|skinparam entity {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|skinparam boundary {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|skinparam agent {
  #|	BackgroundColor $WARNING
  #|	BorderColor $WARNING_LIGHT
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $INFO_BG
  #|	BorderColor $INFO_DARK
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|skinparam artifact {
  #|	BackgroundColor $DARK_BG
  #|	BorderColor $DARK_DARK
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|skinparam component {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|skinparam interface {
  #|	BackgroundColor  $DANGER_DARK
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|skinparam storage {
  #|	BackgroundColor $WARNING_BG
  #|  	BorderColor $WARNING_DARK
  #|	FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|skinparam node {
  #|	BackgroundColor  $PUML_BGCOLOR
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|skinparam cloud {
  #|	BackgroundColor transparent
  #|	BorderColor $DARK
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|skinparam database {
  #|	$primary_scheme()
  #|	FontColor $FGCOLOR
  #|	StereotypeFontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|skinparam class {
  #|	$primary_scheme()
  #|	FontColor $HEADER_TEXT
  #|	HeaderBackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $PRIMARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $PRIMARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|skinparam rectangle {
  #|	BackgroundColor $PUML_BGCOLOR
  #|	FontColor $SECONDARY_TEXT
  #|	BorderColor $SECONDARY_TEXT
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|skinparam package {
  #|	BackgroundColor $PUML_BGCOLOR
  #|  	BorderColor $SECONDARY_TEXT
  #|	FontColor $SECONDARY_TEXT
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|skinparam folder {
  #|	BackgroundColor $SECONDARY_BG
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|skinparam frame {
  #|	BackgroundColor $SECONDARY_BG
  #|  	BorderColor $INFO
  #|	FontColor $INFO
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|skinparam state {
  #|	$primary_scheme()
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|skinparam card {
  #|	BackgroundColor $INFO_BG
  #|	BorderColor $INFO_DARK
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|skinparam file {
  #|	BackgroundColor $SECONDARY_BG
  #|	BorderColor $LIGHT
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|
  #|!startsub map
  #|skinparam map {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|''
  #|'' When mixing skinparam and <style>, it is very important to put <style> after skinparam
  #|''
  #|'' Style settings
  #|''
  #|<style>
  #|participant {
  #|  Margin 5 40
  #|  Padding 15 20
  #|}
  #|wbsDiagram, mindmapDiagram {
  #|  root {
  #|    BackgroundColor $PUML_BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $INFO_BG
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|    $primary_scheme()
  #|    Padding 15
  #|    RoundCorner 20
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY_BG
  #|    FontColor $INFO_BG
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $PUML_BGCOLOR
  #|    FontColor $DARK_BG
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $PUML_BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $SECONDARY_LIGHT-$SECONDARY_BG
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $SECONDARY_BG
  #|  }
  #|}
  #|nwdiagDiagram {
  #|  network {
  #|    $primary_scheme()
  #|    LineColor $PRIMARY_BG
  #|    LineThickness 1.0
  #|    FontColor $PRIMARY_DARK
  #|  }
  #|  server {
  #|    $primary_scheme()
  #|  }
  #|  arrow {
  #|    FontColor $PRIMARY_DARK
  #|    LineColor $PRIMARY_DARK
  #|  }
  #|  group {
  #|    BackGroundColor $LIGHT_BG
  #|    LineColor $LIGHT_DARK
  #|    LineThickness 2.0
  #|    Margin 5
  #|    Padding 5
  #|  }
  #|}
  #|ganttDiagram {
  #|  task {
  #|    $primary_scheme()
  #|	LineColor $PRIMARY_BG
  #|    Margin 10 2 2 2
  #|    Padding 6
  #|  }
  #|  note {
  #|	FontColor $INFO_TEXT
  #|	LineColor $INFO_DARK
  #|    BackGroundColor $INFO_BG
  #|  }
  #|  separator {
  #|	LineColor $SECONDARY_BG
  #|    BackGroundColor $secondary_scheme()
  #|    FontColor $SECONDARY_TEXT
  #|  }
  #|  milestone {
  #|	FontColor $INFO_BG
  #|	FontSize 16
  #|	FontStyle italic
  #|	BackGroundColor $DIAMOND_BG
  #|	LineColor $SECONDARY_DARK
  #|  }
  #|  timeline {
  #|    BackgroundColor $SECONDARY_BG
  #|    FontColor $SECONDARY_TEXT
  #|  }
  #|  closed {
  #|	BackgroundColor $WARNING_DARK
  #|	FontColor $WARNING_TEXT
  #|  }
  #|}
  #|</style>
  #|

///|
// name: black-knight
// display_name: Black Knight
// description: Colors representing the black knight. Looks best on a dark background.
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration:
let builtin_theme_3 : String =
  #|
  #|!$THEME = "black-knight"
  #|''
  #|'' Assume if the background is transparent, that the
  #|'' background will be dark for this theme
  #|''
  #|!assume transparent dark
  #|''
  #|'' If no background color is given, then default transparent
  #|''
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "transparent"
  #|!endif
  #|''
  #|''
  #|'' If no gradient is given, default to 20
  #|''
  #|!if %not(%variable_exists("$GRADIENT"))
  #|!$GRADIENT = 20
  #|!endif
  #|''
  #|skinparam backgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|''
  #|'' Default color palette to be used in the definitions below
  #|''
  #|!$PRIMARY = "#303030"
  #|!$PRIMARY_DARK = %darken($PRIMARY, $GRADIENT)
  #|!$PRIMARY_LIGHT = %lighten($PRIMARY, $GRADIENT)
  #|!$PRIMARY_TEXT = "#fff200"
  #|!$SECONDARY = "#484848"
  #|!$SECONDARY_DARK = %darken($SECONDARY, $GRADIENT)
  #|!$SECONDARY_LIGHT = %lighten($SECONDARY, $GRADIENT)
  #|!$SECONDARY_TEXT = "#fefefe"
  #|!$SUCCESS = "#00FF00"
  #|!$SUCCESS_DARK = %darken($SUCCESS, $GRADIENT)
  #|!$SUCCESS_LIGHT = %lighten($SUCCESS, $GRADIENT)
  #|!$SUCCESS_TEXT = "ffffff"
  #|!$INFO = "#0060a8"
  #|!$INFO_DARK = %darken($INFO, $GRADIENT)
  #|!$INFO_LIGHT = %lighten($INFO, $GRADIENT)
  #|!$INFO_TEXT = "ffffff"
  #|!$WARNING = "#ff8000"
  #|!$WARNING_DARK = %darken($WARNING, $GRADIENT)
  #|!$WARNING_LIGHT = %lighten($WARNING, $GRADIENT)
  #|!$WARNING_TEXT = "#222222"
  #|!$DANGER = "#ff0000"
  #|!$DANGER_DARK = %darken($DANGER, $GRADIENT)
  #|!$DANGER_LIGHT = %lighten($DANGER, $GRADIENT)
  #|!$DANGER_TEXT = "ffffff"
  #|!$LIGHT = "#fff200"
  #|!$DARK = "#484848"
  #|''
  #|'' proc to highlight text in the success color
  #|''
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|''
  #|'' proc to highlight text in the danger color
  #|''
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|''
  #|'' proc to highlight text in the warning color
  #|''
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|''
  #|'' proc to highlight text in the info color
  #|''
  #|!procedure $info($msg)
  #|  <font color=$INFO><b>$msg
  #|!endprocedure
  #|''
  #|'' proc to generate color scheme for primary color
  #|''
  #|!procedure $primary_scheme()
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY_DARK
  #|	BackgroundColor $PRIMARY_LIGHT-$PRIMARY_DARK
  #|!endprocedure
  #|''
  #|'' proc to generate color scheme for secondary color
  #|''
  #|!procedure $secondary_scheme()
  #|	FontColor $SECONDARY_TEXT
  #|	BorderColor $SECONDARY_DARK
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY_DARK
  #|!endprocedure
  #|
  #|skinparam  {
  #|    defaultFontName   "Verdana"
  #|    defaultFontSize   12
  #|    defaultTextAlignment center
  #|    shadowing false
  #|    RoundCorner 10
  #|    TitleFontSize 18
  #|    ' TitleFontColor $PRIMARY_TEXT
  #|}
  #|''
  #|'' Style settings
  #|''
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $ORANGE
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|   Padding 15
  #|   roundcorner 20
  #|   BackgroundColor $PRIMARY-$PRIMARY_DARK
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY
  #|    FontColor $INFO
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $DARK
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|  }
  #|  nwdiagDiagram {
  #|	network {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontColor $PRIMARY_LIGHT
  #|	}
  #|	server {
  #|		$primary_scheme()
  #|	}
  #|	arrow {
  #|		FontColor $PRIMARY_LIGHT
  #|		LineColor $PRIMARY_LIGHT
  #|	}
  #|	group {
  #|		BackGroundColor $LIGHT
  #|		LineColor $LIGHT_DARK
  #|		LineThickness 2.0
  #|		Margin 5
  #|		Padding 5
  #|	}
  #|  }
  #|  participant {
  #|    Margin 5 40
  #|    Padding 15 20
  #|  }
  #|  ganttDiagram {
  #|	task {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		Margin 10 2 2 2
  #|		Padding 6
  #|	}
  #|	note {
  #|		FontColor $INFO_TEXT
  #|		LineColor $INFO_DARK
  #|		BackGroundColor $INFO
  #|	}
  #|	separator {
  #|		LineColor $SECONDARY
  #|		BackGroundColor $SECONDARY-$SECONDARY_DARK
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	milestone {
  #|		FontColor $INFO
  #|		FontSize 16
  #|		FontStyle italic
  #|		BackGroundColor $SECONDARY
  #|		LineColor $SECONDARY_DARK
  #|	}
  #|	timeline {
  #|		BackgroundColor $SECONDARY
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	closed {
  #|		BackgroundColor $WARNING_DARK
  #|		FontColor $WARNING_TEXT
  #|	}
  #|  }
  #|</style>
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName       "Verdana"
  #|skinparam defaultFontSize       12
  #|skinparam dpi                   100
  #|skinparam shadowing             false
  #|skinparam roundcorner           8
  #|skinparam BoxPadding            40
  #|skinparam ArrowColor            $DARK
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_DARK
  #|    CBorderColor $SECONDARY_LIGHT
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|
  #|skinparam title {
  #|	FontColor	                 $SECONDARY_TEXT
  #|	BorderColor	                 $SECONDARY_DARK
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor              $SECONDARY_LIGHT-$SECONDARY
  #|}
  #|
  #|skinparam legend {
  #|	BackgroundColor $PRIMARY
  #|	BorderColor $PRIMARY_DARK
  #|	FontColor $PRIMARY_TEXT
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $SECONDARY_LIGHT-$SECONDARY_DARK
  #|  	DiamondBorderColor $SECONDARY_DARK
  #|  	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|skinparam actor {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|skinparam sequence {
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $BGCOLOR
  #|	BoxBorderColor $DARK
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $SECONDARY
  #|	LifeLineBorderThickness 2
  #|	LifeLineBackgroundColor $SECONDARY_DARK
  #|	''
  #|	GroupBorderColor $DARK
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO
  #|	GroupBackgroundColor $SECONDARY
  #|	GroupBodyBackgroundColor $BGCOLOR
  #|	GroupHeaderBackgroundColor $BGCOLOR
  #|	''
  #|	DividerBackgroundColor $DARK
  #|    DividerBorderColor $DARK
  #|    DividerBorderThickness 2
  #|    DividerFontColor $LIGHT
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceBorderColor $DARK
  #|	ReferenceFontColor $SECONDARY_TEXT
  #|	ReferenceHeaderBackgroundColor $SECONDARY
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY_LIGHT
  #|	BackgroundColor $BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|skinparam control {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|skinparam entity {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|skinparam boundary {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|skinparam agent {
  #|	BackgroundColor $WARNING
  #|	BorderColor $WARNING_LIGHT
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $INFO
  #|	BorderColor $INFO_DARK
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|skinparam artifact {
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY_DARK
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|skinparam component {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|skinparam interface {
  #|	BackgroundColor  $DANGER_DARK
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|skinparam storage {
  #|	BackgroundColor $WARNING_LIGHT-$WARNING_DARK
  #|  	BorderColor $WARNING_DARK
  #|	FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|skinparam node {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $PRIMARY_LIGHT
  #|	FontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|skinparam cloud {
  #|	BackgroundColor transparent
  #|	BorderColor $PRIMARY_LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|skinparam database {
  #|	$primary_scheme()
  #|	BackgroundColor  $BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|skinparam class {
  #|	$primary_scheme()
  #|	HeaderBackgroundColor $SECONDARY_DARK-$SECONDARY
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $LIGHT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|skinparam rectangle {
  #|	$primary_scheme()
  #|	BackgroundColor $BGCOLOR
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|skinparam package {
  #|	$primary_scheme()
  #|	BackgroundColor $BGCOLOR
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|skinparam folder {
  #|	BackgroundColor $SECONDARY_LIGHT
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|skinparam frame {
  #|	BackgroundColor $SECONDARY_LIGHT
  #|  	BorderColor $INFO
  #|	FontColor $INFO
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|skinparam state {
  #|	$primary_scheme()
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|skinparam card {
  #|	BackgroundColor $INFO_LIGHT-$INFO_DARK
  #|	BorderColor $INFO_DARK
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|skinparam file {
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY_DARK
  #|	BorderColor $INFO
  #|	FontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!if %variable_exists("NEWSTYLE")
  #|<>
  #|wbsDiagram {
  #|    LineColor $PRIMARY
  #|    BorderThickness 3
  #|    BackgroundColor $LIGHT
  #|    FontColor $PRIMARY_TEXT
  #|    :depth(0) {
  #|        fontSize 16
  #|        fontStyle bold
  #|        fontColor $SECONDARY
  #|    }
  #|    :depth(1) {
  #|        fontSize 14
  #|        padding 5
  #|        fontStyle bold
  #|    }
  #|    :depth(2) {
  #|        fontSize 12
  #|        padding 4
  #|    }
  #|    :depth(3) {
  #|        fontSize 11
  #|        padding 3
  #|        fontColor $INFO
  #|    }
  #|
  #|}
  #|</>
  #|!endif

///|
// name: bluegray
// display_name: Blue Gray
// description: A blue gray theme
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration:
let builtin_theme_4 : String =
  #|
  #|!$THEME = "bluegray"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "transparent"
  #|!endif
  #|
  #|skinparam backgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|
  #|
  #|!$WHITE = "#fff"
  #|!$GRAY_DARK = "#5a5a5a"
  #|!$GRAY = "#959595"
  #|!$PRIMARY = "#009fdb"
  #|!$SECONDARY = "#f2f2f2"
  #|!$SUCCESS = "#b5bd00"
  #|!$INFO = "#0568ae"
  #|!$WARNING = "#ea7400"
  #|!$DANGER = "#cf2a2a"
  #|!$LIGHT = "#d2d2d2"
  #|!$DARK = "#5a5a5a"
  #|
  #|!$FGCOLOR = $DARK
  #|!$PRIMARY_LIGHT = "#33b2e2"
  #|!$PRIMARY_DARK = "#007faf"
  #|!$PRIMARY_TEXT = $WHITE
  #|!$SECONDARY_LIGHT = "#f5f5f5"
  #|!$SECONDARY_DARK = "#c2c2c2"
  #|!$SECONDARY_TEXT = $DARK
  #|!$INFO_LIGHT = "#3786be"
  #|!$INFO_DARK = "#04538b"
  #|!$INFO_TEXT = $WHITE
  #|!$SUCCESS_LIGHT = "#c4ca33"
  #|!$SUCCESS_DARK = "#919700"
  #|!$SUCCESS_TEXT = $WHITE
  #|!$WARNING_LIGHT = "#ee9033"
  #|!$WARNING_DARK = "#bb5d00"
  #|!$WARNING_TEXT = $WHITE
  #|!$DANGER_LIGHT = "#d95555"
  #|!$DANGER_DARK = "#a62222"
  #|!$DANGER_TEXT = $WHITE
  #|
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|
  #|!procedure $primary_scheme()
  #|
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY_LIGHT
  #|	BackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|
  #|!endprocedure
  #|
  #|!procedure $secondary_scheme()
  #|	FontColor $SECONDARY_TEXT
  #|	BorderColor $SECONDARY_DARK
  #|	BackgroundColor $WHITE-#fefefe
  #|!endprocedure
  #|''
  #|'' Style settings
  #|''
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $ORANGE
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|   Padding 15
  #|   roundcorner 20
  #|   BackgroundColor $PRIMARY-$PRIMARY_DARK
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY
  #|    FontColor $INFO
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $DARK
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|  }
  #|  nwdiagDiagram {
  #|	network {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontColor $PRIMARY_DARK
  #|	}
  #|	server {
  #|		$primary_scheme()
  #|	}
  #|	arrow {
  #|		FontColor $PRIMARY_DARK
  #|		LineColor $PRIMARY_DARK
  #|	}
  #|	group {
  #|		BackGroundColor $LIGHT
  #|		LineColor $LIGHT_DARK
  #|		LineThickness 2.0
  #|		Margin 5
  #|		Padding 5
  #|	}
  #|  }
  #|  participant {
  #|    Margin 5 30
  #|    Padding 15 20
  #|  }
  #|  ganttDiagram {
  #|	task {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		Margin 10 2 2 2
  #|		Padding 6
  #|	}
  #|	note {
  #|		FontColor $INFO_TEXT
  #|		LineColor $INFO_DARK
  #|		BackGroundColor $INFO
  #|	}
  #|	separator {
  #|		LineColor $SECONDARY
  #|		BackGroundColor $SECONDARY-$SECONDARY_DARK
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	milestone {
  #|		FontColor $INFO
  #|		FontSize 16
  #|		FontStyle italic
  #|		BackGroundColor $SECONDARY
  #|		LineColor $SECONDARY_DARK
  #|	}
  #|	timeline {
  #|		BackgroundColor $SECONDARY
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	closed {
  #|		BackgroundColor $WARNING_DARK
  #|		FontColor $WARNING_TEXT
  #|	}
  #|  }
  #|</style>
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName        "Verdana"
  #|skinparam defaultFontSize        12
  #|skinparam dpi                    100
  #|skinparam shadowing              false
  #|skinparam roundcorner            20
  #|skinparam BoxPadding             40
  #|skinparam ArrowColor             $GRAY
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_LIGHT
  #|    CBorderColor $SECONDARY_DARK
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontColor	                 $PRIMARY
  #|	BorderColor	                 $SECONDARY_DARK
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor              $SECONDARY_LIGHT-$SECONDARY
  #|}
  #|
  #|
  #|skinparam legend {
  #|	BackgroundColor $SECONDARY
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $DARK
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|
  #|skinparam activity {
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY
  #|	BackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $SECONDARY_LIGHT-$SECONDARY_DARK
  #|  	DiamondBorderColor $SECONDARY_DARK
  #|	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	$primary_scheme()
  #|	FontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|
  #|skinparam sequence {
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $LIGHT
  #|	BoxBorderColor $GRAY
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $SECONDARY_DARK
  #|	LifeLineBorderThickness 2
  #|	LifeLineBackgroundColor $SECONDARY_LIGHT
  #|	''
  #|	GroupBorderColor $GRAY
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO
  #|	''
  #|	DividerBackgroundColor $WHITE-$LIGHT
  #|    DividerBorderColor $GRAY
  #|    DividerBorderThickness 2
  #|    DividerFontColor $DARK
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceBorderColor $GRAY
  #|	ReferenceFontColor $DARK
  #|	ReferenceHeaderFontColor $INFO
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|
  #|skinparam control {
  #|	$primary_scheme()
  #|	FontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|
  #|skinparam entity {
  #|	$primary_scheme()
  #|	FontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|
  #|skinparam boundary {
  #|	$primary_scheme()
  #|	FontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|
  #|skinparam agent {
  #|	BackgroundColor #orange
  #|	BorderColor #999999
  #|	FontColor #333333
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $INFO_LIGHT-$INFO
  #|	BorderColor $INFO
  #|	FontColor $WHITE
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|
  #|skinparam artifact {
  #|	BackgroundColor $WHITE-$LIGHT
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|
  #|skinparam component {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|
  #|skinparam interface {
  #|	BackgroundColor  $DANGER_LIGHT
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|
  #|skinparam storage {
  #|	BackgroundColor $WARNING_LIGHT-$WARNING
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|
  #|skinparam node {
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|
  #|skinparam cloud {
  #|	BackgroundColor #F2FCFE-#eeeeee
  #|	BorderColor #F2FCFE
  #|	FontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|
  #|skinparam database {
  #|	$primary_scheme()
  #|	' FontColor $PRIMARY
  #|	BorderColor $PRIMARY_DARK
  #|	' BackgroundColor  $BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|
  #|skinparam class {
  #|	$primary_scheme()
  #|	HeaderBackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $LIGHT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $LIGHT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|
  #|skinparam rectangle {
  #|	$secondary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|
  #|skinparam package {
  #|	FontColor $PRIMARY
  #|	BorderColor $PRIMARY_LIGHT
  #|	BackgroundColor $BGCOLOR
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|
  #|skinparam folder {
  #|	BackgroundColor $WHITE-$SECONDARY_LIGHT
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|
  #|skinparam frame {
  #|	BackgroundColor $WHITE-$SECONDARY_LIGHT
  #|  	BorderColor $INFO
  #|	FontColor $INFO
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|
  #|skinparam state {
  #|	$primary_scheme()
  #|	BorderColor $PRIMARY_DARK
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $LIGHT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|
  #|skinparam card {
  #|	BackgroundColor $INFO_LIGHT-$INFO
  #|	BorderColor $INFO
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|
  #|skinparam file {
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY
  #|	BorderColor $INFO
  #|	FontColor $SECONDARY_TEXT
  #|
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub

///|
// name: blueprint
// display_name: Blueprint
// description: A white on blue theme based on the Blueprint reproduction process
// author: Matthew Leather
// release:
// license:
// version:
// source:
// inspiration: https://en.wikipedia.org/wiki/Blueprint
let builtin_theme_5 : String =
  #|
  #|!$THEME = "blueprint"
  #|
  #|!$BGCOLOR = "#003153"
  #|!$FGCOLOR = "#D9D3D0"
  #|
  #|!ifndef $FONT_NAME
  #|  !$FONT_NAME = "Verdana"
  #|!endif
  #|
  #|!ifndef $FONT_NAME_MONOSPACED
  #|  !$FONT_NAME_MONOSPACED = "Courier"
  #|!endif
  #|
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $FGCOLOR
  #|    FontName $FONT_NAME
  #|    HyperLinkColor $FGCOLOR
  #|    LineColor $FGCOLOR
  #|    LineThickness 1
  #|    Margin 5
  #|  }
  #|  document {
  #|    caption {
  #|      LineThickness 0
  #|    }
  #|    footer {
  #|      LineThickness 0
  #|    }
  #|    header {
  #|      LineThickness 0
  #|    }
  #|    title {
  #|      FontSize 22
  #|      LineThickness 0
  #|    }
  #|  }
  #|  node {
  #|    MaximumWidth 300
  #|  }
  #|  participant {
  #|    Margin 5 10
  #|    Padding 5 5
  #|  }
  #|</style>
  #|
  #|skinparam ArrowLollipopColor $FGCOLOR
  #|skinparam BackgroundColor $BGCOLOR
  #|skinparam DefaultFontName $FONT_NAME
  #|skinparam DefaultMonospacedFontName $FONT_NAME_MONOSPACED
  #|skinparam LifelineStrategy nosolid
  #|skinparam SequenceLifeLineBorderColor $FGCOLOR
  #|skinparam Shadowing false
  #|skinparam UseBetaStyle true
  #|
  #|skinparam Activity {
  #|  BackgroundColor $BGCOLOR
  #|  BarColor $FGCOLOR
  #|  BorderColor $FGCOLOR
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Boundary {
  #|  FontColor $FGCOLOR
  #|}
  #|skinparam Box {
  #|  Padding 5
  #|}
  #|skinparam CircledCharacter {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME_MONOSPACED
  #|  Radius 9
  #|}
  #|skinparam Class {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam ClassAttribute {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam ClassStereotype {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Footer {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Header {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Hyperlink {
  #|  Color $FGCOLOR
  #|}
  #|skinparam IconPackage {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam IconPrivate {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam IconProtected {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam IconPublic {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam Note {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Object {
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam Package {
  #|  BorderColor $FGCOLOR
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam State {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeA {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeC {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeE {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeI {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeN {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam UseCaseStereoType {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}

///|
// name: carbon-gray
// display_name: Carbon Gray
// description: A gray theme using the IBM Carbon Design Gray palette
// author: Bharat Rajagopalan
// release:
// license:
// version:
// source:
// inspiration: https://carbondesignsystem.com/elements/color/overview/
let builtin_theme_6 : String =
  #|
  #|!$THEME = "carbon-gray"
  #|
  #|'!$BGCOLOR = "#f5f5f5"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "transparent"
  #|!endif
  #|
  #|skinparam backgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|
  #|!$RED_80 = '#750e13'
  #|!$RED_70 = '#a2191f'
  #|!$RED_60 = '#da1e28'
  #|!$RED_50 = '#fa4d56'
  #|!$RED_40 = '#ff8389'
  #|!$RED_30 = '#ffb3b8'
  #|!$RED_20 = '#ffd7d9'
  #|!$RED_10 =  '#fff1f1'
  #|
  #|!$CYAN_10 = '#e5f6ff'
  #|!$CYAN_20 = '#bae6ff'
  #|!$CYAN_30 = '#82cfff'
  #|!$CYAN_40 = '#33b1ff'
  #|!$CYAN_50 = '#1192e8'
  #|!$CYAN_60 = '#0072c3'
  #|!$CYAN_70 = '#00539a'
  #|!$CYAN_80 = '#003a6d'
  #|
  #|
  #|!$PURPLE_80 ='#491d8b'
  #|!$PURPLE_70 = '#6929c4'
  #|!$PURPLE_60 = '#8a3ffc'
  #|!$PURPLE_50 = '#a56eff'
  #|!$PURPLE_40 = '#be95ff'
  #|!$PURPLE_30 = '#d4bbff'
  #|!$PURPLE_20 = '#e8daff'
  #|!$PURPLE_10 = '#f6f2ff'
  #|
  #|!$TEAL_10 = '#d9fbfb'
  #|!$TEAL_20 = '#9ef0f0'
  #|!$TEAL_30 = '#3ddbd9'
  #|!$TEAL_40 = '#08bdba'
  #|!$TEAL_50 = '#009d9a'
  #|!$TEAL_60 = '#007d79'
  #|!$TEAL_70 = '#005d5d'
  #|!$TEAL_80 = '#004144'
  #|
  #|!$GRAY_10 = '#f4f4f4'
  #|!$GRAY_20 = '#e0e0e0'
  #|!$GRAY_30 = '#c6c6c6'
  #|!$GRAY_40 = '#a8a8a8'
  #|!$GRAY_50 = '#8d8d8d'
  #|!$GRAY_60 = '#6f6f6f'
  #|!$GRAY_70 = '#525252'
  #|!$GRAY_80 = '#393939'
  #|!$GRAY_90 = '#262626'
  #|!$GRAY_100 = '#161616'
  #|!$WHITE = '#FFFFF'
  #|
  #|!$GRAY_DARK = $GRAY_100
  #|!$GRAY = $GRAY_30
  #|!$LIGHT = $GRAY_70
  #|!$DARK = $GRAY_90
  #|
  #|'' *_LIGHT = tint (lighter) of the main color of 80%
  #|''          where TINT is calculated by clr + (255-clr) * tint_factor
  #|'' *_DARK = shade (darker) of the main color of 80%
  #|''          and SHADE is calculated by clr * (1 - shade_factor)
  #|''
  #|!$FGCOLOR = $DARK
  #|!$PRIMARY = $GRAY_10
  #|!$PRIMARY_LIGHT = $GRAY_10
  #|!$PRIMARY_DARK = $GRAY_30
  #|!$PRIMARY_TEXT = $DARK
  #|!$SECONDARY = $GRAY_10
  #|!$SECONDARY_LIGHT = $GRAY_10
  #|!$SECONDARY_DARK = $GRAY_30
  #|!$SECONDARY_TEXT = $DARK
  #|!$INFO = $WHITE
  #|!$INFO_LIGHT = $GRAY_20
  #|!$INFO_DARK = $GRAY_30
  #|!$INFO_TEXT = $DARK
  #|!$SUCCESS = $DARK
  #|!$SUCCESS_LIGHT = $DARK
  #|!$SUCCESS_DARK = $DARK
  #|!$SUCCESS_TEXT = $WHITE
  #|!$WARNING = $WHITE
  #|!$WARNING_LIGHT = $WHITE
  #|!$WARNING_DARK = $WHITE
  #|!$WARNING_TEXT = $DARK
  #|!$DANGER = $WHITE
  #|!$DANGER_LIGHT = $WHITE
  #|!$DANGER_DARK = $WHITE
  #|!$DANGER_TEXT = $DARK
  #|
  #|!$OTHER_BG = $WHITE
  #|!$DB_BG = $GRAY
  #|!$LINE_THICKNESS = 1
  #|!$BORDER_THICKNESS = 1
  #|
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|
  #|!procedure $primary_scheme()
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY_DARK
  #|	BackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|	RoundCorner 0
  #|!endprocedure
  #|
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName        "IBM Plex Sans, Noto Sans, Verdana"
  #|skinparam defaultFontSize        12
  #|'skinparam dpi                    125
  #|skinparam shadowing              false
  #|skinparam roundcorner            0
  #|skinparam BoxPadding             30
  #|skinparam ArrowColor             $GRAY
  #|<style>
  #|participant {
  #|  Margin 5 30
  #|  Padding 15 20
  #|}
  #|</style>
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_LIGHT
  #|    CBorderColor $SECONDARY_DARK
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontColor	                 $SECONDARY_TEXT
  #|	BorderColor	                 $SECONDARY
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         0
  #|	BackgroundColor              $BGCOLOR
  #|}
  #|
  #|
  #|skinparam legend {
  #|	BackgroundColor $OTHER_BG
  #|	BorderColor $DARK
  #|	FontColor $PRIMARY_TEXT
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $PRIMARY
  #|	BorderThickness $LINE_THICKNESS
  #|	TitleBackgroundColor  $PRIMARY_LIGHT-$PRIMARY
  #|	TitleFontColor $PRIMARY_TEXT
  #|	BackgroundColor $BG_COLOR
  #|	TitleFontStyle bold
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $DARK
  #|	StartColor $LIGHT-$DARK
  #|	EndColor $LIGHT-$DARK
  #|	''
  #|	DiamondBackgroundColor $SECONDARY_LIGHT-$SECONDARY
  #|  	DiamondBorderColor $SECONDARY
  #|	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness $BORDER_THICKNESS
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|
  #|skinparam arrow {
  #|	Thickness $LINE_THICKNESS
  #|	Color $GRAY
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|
  #|skinparam sequence {
  #|	BorderColor $PRIMARY_DARK
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $SECONDARY_TEXT
  #|	BackgroundColor $OTHER_BG
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $OTHER_BG
  #|	BoxBorderColor $PRIMARY_DARK
  #|	BoxFontColor $PRIMARY_TEXT
  #|	''
  #|	DelayFontColor $PRIMARY_TEXT
  #|	''
  #|	LifeLineBorderColor $PRIMARY_DARK
  #|	LifeLineBorderThickness $LINE_THICKNESS
  #|	LifeLineBackgroundColor $PRIMARY
  #|	''
  #|	GroupBorderColor $PRIMARY_DARK
  #|	GroupFontColor $PRIMARY_TEXT
  #|	GroupFontStyle bold
  #|	GroupHeaderFontColor $INFO_TEXT
  #|	GroupBackgroundColor $PRIMARY
  #|	GroupBodyBackgroundColor $OTHER_BG
  #|	GroupHeaderBackgroundColor $PRIMARY
  #|	''
  #|	DividerBackgroundColor $PRIMARY
  #|    DividerBorderColor $PRIMARY_DARK
  #|    DividerBorderThickness $LINE_THICKNESS
  #|    DividerFontColor $PRIMARY_TEXT
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceHeaderBorderColor $PRIMARY_DARK
  #|	ReferenceHeaderBackgroundColor $PRIMARY
  #|	ReferenceBorderColor $PRIMARY_DARK
  #|	ReferenceFontColor $DARK
  #|	ReferenceHeaderFontColor $INFO_TEXT
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY_TEXT
  #|	BackgroundColor $OTHER_BG
  #|	fontStyle bold
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|
  #|skinparam control {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|
  #|skinparam entity {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|
  #|skinparam boundary {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|
  #|skinparam agent {
  #|	BackgroundColor $PRIMARY_LIGHT
  #|	BorderColor $PRIMARY_DARK
  #|	FontColor $PRIMARY_TEXT
  #|	RoundCorner 0
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $INFO_LIGHT-$INFO
  #|	BorderColor $DARK
  #|	FontColor $INFO_TEXT
  #|	RoundCorner 0
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|
  #|skinparam artifact {
  #|	BackgroundColor $PRIMARY
  #|	BorderColor $PRIMARY_DARK
  #|	FontColor $DARK
  #|	RoundCorner 0
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|
  #|skinparam component {
  #|	$primary_scheme()
  #|	BackgroundColor $PRIMARY
  #|	BorderColor $PRIMARY_DARK
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|
  #|skinparam interface {
  #|	BackgroundColor  $PRIMARY_DARK
  #|	BorderColor  $PRIMARY_DARK
  #|	FontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|
  #|skinparam storage {
  #|	BackgroundColor $OTHER_BG
  #|  	BorderColor $DARK
  #|	FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|
  #|skinparam node {
  #|	BackgroundColor $OTHER_BG
  #|	BorderColor $PRIMARY_DARK
  #|	FontColor $PRIMARY_TEXT
  #|	Roundcorner 0
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|
  #|skinparam cloud {
  #|	BackgroundColor $OTHER_BG
  #|	BorderColor $PRIMARY_DARK
  #|	FontColor $PRIMARY_TEXT
  #|	Roundcorner 0
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|
  #|skinparam database {
  #|	$primary_scheme()
  #|	BorderColor $PRIMARY_DARK
  #|	BackgroundColor  $OTHER_BG
  #|	Roundcorner 0
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|
  #|skinparam class {
  #|	$primary_scheme()
  #|	HeaderBackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|	StereotypeFontSize 9
  #|	BorderThickness $LINE_THICKNESS
  #|	AttributeFontColor $PRIMARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|	BorderThickness $BORDER_THICKNESS
  #|	AttributeFontColor $PRIMARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness $BORDER_THICKNESS
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|
  #|skinparam rectangle {
  #|	$primary_scheme()
  #|	BackgroundColor $OTHER_BG
  #|	BorderThickness $BORDER_THICKNESS
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|
  #|skinparam package {
  #|	$primary_scheme()
  #|	BackgroundColor $OTHER_BG
  #|	BorderThickness $BORDER_THICKNESS
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|
  #|skinparam folder {
  #|	BackgroundColor $OTHER_BG
  #|  	BorderColor $PRIMARY_DARK
  #|	FontColor $WARNING_TEXT
  #|	BorderThickness $BORDER_THICKNESS
  #|	Roundcorner 0
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|
  #|skinparam frame {
  #|	BackgroundColor $OTHER_BG
  #|  	BorderColor $PRIMARY_DARK
  #|	FontColor $DARK
  #|	BorderThickness $BORDER_THICKNESS
  #|	Roundcorner 0
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|
  #|skinparam state {
  #|	$primary_scheme()
  #|	BorderColor $PRIMARY_DARK
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|
  #|skinparam queue {
  #|	$primary_scheme()
  #|
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|
  #|skinparam card {
  #|	BackgroundColor $OTHER_BG
  #|	BorderColor $PRIMARY_DARK
  #|	FontColor $INFO_TEXT
  #|	RoundCorner 0
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|
  #|skinparam file {
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $SECONDARY_TEXT
  #|	RoundCorner 0
  #|
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub person
  #|
  #|skinparam person {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|
  #|!if (%variable_exists("LEGACY"))
  #|!$LEGACY = "true"
  #|!endif
  #|
  #|!if (%getenv("LEGACY") == "true")
  #|!$LEGACY = "true"
  #|!endif
  #|
  #|'!if (not %variable_exists("$LEGACY"))
  #|
  #|skinparam useBetaStyle true
  #|
  #|!startsub mindmap
  #|
  #|<style>
  #|
  #|boardDiagram {
  #|	node {
  #|	$primary_scheme()
  #|    BackGroundColor  $PRIMARY
  #|    LineColor $PRIMARY_DARK
  #|    FontName "IBM Plex Sans, Noto Sans, Verdana"
  #|    'FontColor
  #|    FontSize 12
  #|    'FontStyle bold
  #|    RoundCorner 0
  #|    'LineThickness 2
  #|    'LineStyle 10-5
  #|    separator {
  #|      LineThickness $LINE_THICKNESS
  #|      LineColor $PRIMARY_DARK
  #|      'LineStyle 1-5
  #|    }
  #|  }
  #|}
  #|
  #|ganttDiagram {
  #|
  #|  task {
  #|    BackGroundColor $PRIMARY
  #|    LineColor $PRIMARY_DARK
  #|	FontStyle Bold
  #|	FontSize 12
  #|    unstarted {
  #|      BackGroundColor $PRIMARY_LIGHT
  #|      LineColor $PRIMARY_DARK
  #|	  'FontColor $RED_80
  #|    }
  #|	Padding 3
  #|	Margin 3
  #|
  #|  }
  #|  timeline {
  #|	LineColor $PRIMARY
  #|	FontColor $WHITE
  #|	BackgroundColor $DARK
  #|    FontName Helvetica
  #|    'FontSize 12
  #|    FontStyle bold
  #|	YearFontColor $WHITE
  #|	QuarterFontColor $WHITE
  #|	MonthFontColor $WHITE
  #|	WeekFontColor $WHITE
  #|	WeekdayFontColor $WHITE
  #|	DayFontColor $WHITE
  #|  }
  #|  arrow {
  #|		'FontName Helvetica
  #|		'FontColor red
  #|		FontSize 12
  #|		FontStyle bold
  #|		'BackGroundColor GreenYellow
  #|		LineColor $PRIMARY_DARK
  #|		'LineStyle 8.0-13.0
  #|		'LineThickness 3.0
  #|	}
  #|
  #|  milestone {
  #|		FontColor $PRIMARY_TEXT
  #|		FontSize 12
  #|		FontStyle  bold
  #|		BackGroundColor $DARK
  #|		LineColor $DARK
  #|	}
  #|  separator {
  #|		BackgroundColor $PRIMARY
  #|		'LineStyle 8.0-3.0
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontSize 12
  #|		FontStyle bold
  #|		FontColor  $PRIMARY_TEXT
  #|		Margin 3
  #|		'Padding 20
  #|	}
  #|	closed {
  #|		BackgroundColor $RED_20
  #|		FontColor $RED_20
  #|	}
  #|}
  #|
  #|jsonDiagram {
  #|  node {
  #|	$primary_scheme()
  #|    BackGroundColor  $PRIMARY
  #|    LineColor $PRIMARY_DARK
  #|    FontName "IBM Plex Sans, Noto Sans, Verdana"
  #|    'FontColor
  #|    FontSize 12
  #|    'FontStyle bold
  #|    RoundCorner 0
  #|    'LineThickness 2
  #|    'LineStyle 10-5
  #|    separator {
  #|      LineThickness $LINE_THICKNESS
  #|      LineColor $PRIMARY_DARK
  #|      'LineStyle 1-5
  #|    }
  #|  }
  #|  arrow {
  #|    BackGroundColor $PRIMARY_DARK
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness $LINE_THICKNESS
  #|    LineStyle 3-6
  #|  }
  #|  highlight {
  #|    BackGroundColor $PRIMARY_DARK
  #|    FontColor $PRIMARY_TEXT
  #|    FontStyle italic
  #|  }
  #|}
  #|
  #|
  #|mindmapDiagram {
  #|  'Padding 8
  #|  'Margin 8
  #|  LineThickness $LINE_THICKNESS
  #|  FontColor $PRIMARY_TEXT
  #|  LineColor $PRIMARY_DARK
  #|  'BackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|  Roundcorner 0
  #|  node {
  #|    'Padding 12
  #|    'Margin 3
  #|    'HorizontalAlignment center
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness $BORDER_THICKNESS
  #|    BackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|    RoundCorner 0
  #|    MaximumWidth 100
  #|	FontColor $DARK
  #|	'FontStyle bold
  #|  }
  #|}
  #|
  #|'Salt Diagram only has limited skinning
  #|saltDiagram {
  #|  BackGroundColor $BG_COLOR
  #|  'Fontname Monospaced
  #|  'FontSize 10
  #|  'FontStyle italic
  #|  'LineThickness 0.5
  #|  'LineColor PRIMARY_DARK
  #|}
  #|
  #|timingDiagram {
  #|  document {
  #|    BackGroundColor $BG_COLOR
  #|	LineColor $PRIMARY
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY_TEXT
  #|
  #|  }
  #|  highlight {
  #|	 BackGroundColor $PRIMARY
  #|  }
  #|
  #| constraintArrow {
  #|  'LineStyle 2-1
  #|  LineThickness 2
  #|  LineColor $RED_80
  #|  FontColor $RED_80
  #|  FontStyle bold
  #| }
  #|}
  #|
  #|wbsDiagram {
  #|  'Padding 8
  #|  node {
  #|    'Padding 12
  #|    'Margin 3
  #|    'HorizontalAlignment center
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness $BORDER_THICKNESS
  #|    BackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|    RoundCorner 0
  #|    MaximumWidth 100
  #|	FontColor $PRIMARY_TEXT
  #|	'FontStyle bold
  #|  }
  #|  'Margin 8
  #|  'LineThickness $LINE_THICKNESS
  #|  'FontColor $PRIMARY_TEXT
  #|  'LineColor $PRIMARY
  #|  'BorderColor $PRIMARY
  #|  'BackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|  'RoundCorner 0
  #|
  #|  arrow {
  #|	' note that Connectors are actually "Arrows"; this may change in the future
  #|	' so this means all Connectors and Arrows are now going to be green
  #|
  #|    lineColor $PRIMARY_DARK
  #|    fontColor $PRIMARY_TEXT
  #|    thickness $LINE_THICKNESS
  #|  }
  #|
  #|  noteBorderColor $DARK
  #|}
  #|
  #|'Placeholder for adding wirediagram skins
  #|wireDiagram {
  #|}
  #|
  #|yamlDiagram {
  #|  node {
  #|	$primary_scheme()
  #|    BackGroundColor  $PRIMARY
  #|    LineColor $PRIMARY_DARK
  #|    FontName "IBM Plex Sans, Noto Sans, Verdana"
  #|    'FontColor
  #|    FontSize 12
  #|    'FontStyle bold
  #|    RoundCorner 0
  #|    'LineThickness 2
  #|    'LineStyle 10-5
  #|    separator {
  #|      LineThickness $LINE_THICKNESS
  #|      LineColor $PRIMARY_DARK
  #|      'LineStyle 1-5
  #|    }
  #|  }
  #|  arrow {
  #|    BackGroundColor $PRIMARY_DARK
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness $LINE_THICKNESS
  #|    LineStyle 3-6
  #|  }
  #|  highlight {
  #|    BackGroundColor $PRIMARY_DARK
  #|    FontColor $PRIMARY_TEXT
  #|    FontStyle italic
  #|  }
  #|}
  #|</style>
  #|!endsub
  #|'!endif

///|
// name: cerulean-outline
// display_name: Cerulean Outline
// description: Cerulean theme based off of the bootstrap theme of the same name, with outline colors
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration: https://bootswatch.com/cerulean/
let builtin_theme_7 : String =
  #|
  #|!$THEME = "cerulean-outline"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "transparent"
  #|!endif
  #|
  #|skinparam backgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|
  #|''
  #|'' Colors taken from the css file of the BS theme
  #|''
  #|!$BLUE = "#033C73"
  #|!$INDIGO = "#6610F2"
  #|!$PURPLE = "#6F42C1"
  #|!$PINK = "#E83E8C"
  #|!$RED = "#C71C22"
  #|!$ORANGE = "#FD7E14"
  #|!$YELLOW = "#DD5600"
  #|!$GREEN = "#73A839"
  #|!$TEAL = "#20C997"
  #|!$CYAN = "#2FA4E7"
  #|!$WHITE = "#FFF"
  #|!$GRAY_DARK = "#343A40"
  #|!$GRAY = "#868E96"
  #|!$PRIMARY = "#2FA4E7"
  #|!$SECONDARY = "#E9ECEF"
  #|!$SUCCESS = "#73A839"
  #|!$INFO = "#033C73"
  #|!$WARNING = "#DD5600"
  #|!$DANGER = "#C71C22"
  #|!$LIGHT = "#F8F9FA"
  #|!$DARK = "#343A40"
  #|
  #|'' *_LIGHT = tint (lighter) of the main color of 80%
  #|''          where TINT is calculated by clr + (255-clr) * tint_factor
  #|'' *_DARK = shade (darker) of the main color of 80%
  #|''          and SHADE is calculated by clr * (1 - shade_factor)
  #|''
  #|!$FGCOLOR = $DARK
  #|!$PRIMARY_LIGHT = "#59B6EC"
  #|!$PRIMARY_DARK = "#2683B9"
  #|!$PRIMARY_TEXT = $PRIMARY
  #|!$SECONDARY_LIGHT = "#EDF0F2"
  #|!$SECONDARY_DARK = "#BABDBF"
  #|!$SECONDARY_TEXT = $SECONDARY_DARK
  #|!$INFO_LIGHT = "#35638F"
  #|!$INFO_TEXT = $INFO
  #|!$SUCCESS_LIGHT = "#8FB961"
  #|!$SUCCESS_TEXT = $SUCCESS
  #|!$WARNING_LIGHT = "#E47833"
  #|!$WARNING_TEXT = $WARNING
  #|!$DANGER_LIGHT = "#D2494E"
  #|!$DANGER_TEXT = $WHITE
  #|
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|
  #|!procedure $primary_scheme()
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|!endprocedure
  #|''
  #|'' Style settings
  #|''
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $ORANGE
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|   Padding 15
  #|   roundcorner 20
  #|   BackgroundColor $BGCOLOR
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY
  #|    FontColor $INFO
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $DARK
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $BGCOLOR
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|  }
  #|  nwdiagDiagram {
  #|	network {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontColor $PRIMARY_DARK
  #|	}
  #|	server {
  #|		$primary_scheme()
  #|	}
  #|	arrow {
  #|		FontColor $PRIMARY_DARK
  #|		LineColor $PRIMARY_DARK
  #|	}
  #|	group {
  #|		BackGroundColor $LIGHT
  #|		LineColor $LIGHT_DARK
  #|		LineThickness 2.0
  #|		Margin 5
  #|		Padding 5
  #|	}
  #|  }
  #|  participant {
  #|    Margin 5 40
  #|    Padding 15 20
  #|  }
  #|
  #|  ganttDiagram {
  #|	task {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		Margin 10 2 2 2
  #|		Padding 6
  #|	}
  #|	note {
  #|		FontColor $INFO_TEXT
  #|		LineColor $INFO_DARK
  #|		BackGroundColor $BGCOLOR
  #|	}
  #|	separator {
  #|		LineColor $SECONDARY_DARK
  #|		BackGroundColor $BGCOLOR
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	milestone {
  #|		FontColor $INFO
  #|		FontSize 16
  #|		FontStyle italic
  #|		BackGroundColor $SECONDARY
  #|		LineColor $SECONDARY_DARK
  #|	}
  #|	timeline {
  #|		BackgroundColor $SECONDARY
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	closed {
  #|		BackgroundColor $WARNING_DARK
  #|		FontColor $WARNING_TEXT
  #|	}
  #|  }
  #|</style>
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName       "Verdana"
  #|skinparam defaultFontSize       12
  #|skinparam dpi                   100
  #|skinparam shadowing             false
  #|skinparam roundcorner           8
  #|skinparam BoxPadding            40
  #|skinparam ArrowColor            $GRAY
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_LIGHT
  #|    CBorderColor $SECONDARY_DARK
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontColor	                 $PRIMARY
  #|	BorderColor	                 $SECONDARY_DARK
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor              $BGCOLOR
  #|}
  #|
  #|skinparam legend {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $DARK
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $BGCOLOR
  #|  	DiamondBorderColor $SECONDARY_DARK
  #|	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|
  #|skinparam sequence {
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $BGCOLOR
  #|	BoxBorderColor $GRAY
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $SECONDARY_DARK
  #|	LifeLineBorderThickness 2
  #|	LifeLineBackgroundColor $BGCOLOR
  #|	''
  #|	GroupBorderColor $GRAY
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO_TEXT
  #|	''
  #|	DividerBackgroundColor $LIGHT
  #|    DividerBorderColor $GRAY
  #|    DividerBorderThickness 2
  #|    DividerFontColor $DARK
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceBorderColor $GRAY
  #|	ReferenceFontColor $DARK
  #|	ReferenceHeaderFontColor $INFO_TEXT
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|
  #|skinparam control {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|
  #|skinparam entity {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|
  #|skinparam boundary {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|
  #|skinparam agent {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor #999999
  #|	FontColor #333333
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $INFO
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|
  #|skinparam artifact {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $GRAY
  #|	FontColor $GRAY
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|
  #|skinparam component {
  #|	$primary_scheme()
  #|	' BackgroundColor $BGCOLOR
  #|	' BorderColor  $SUCCESS
  #|	' FontColor $SUCCESS_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|
  #|skinparam interface {
  #|	BackgroundColor  $BGCOLOR
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|
  #|skinparam storage {
  #|	BackgroundColor $BGCOLOR
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|
  #|skinparam node {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $DARK
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|
  #|skinparam cloud {
  #|	BackgroundColor #F2FCFE-#eeeeee
  #|	BorderColor #F2FCFE
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|
  #|skinparam database {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|
  #|skinparam class {
  #|	$primary_scheme()
  #|	FontColor $LIGHT
  #|	HeaderBackgroundColor $PRIMARY-$PRIMARY_DARK
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $DARK
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $SECONDARY_DARK
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|
  #|skinparam rectangle {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|
  #|skinparam package {
  #|	BackgroundColor $BGCOLOR
  #|  	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|
  #|skinparam folder {
  #|	BackgroundColor $BGCOLOR
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|
  #|skinparam frame {
  #|	BackgroundColor $BGCOLOR
  #|  	BorderColor $INFO
  #|	FontColor $INFO_TEXT
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|
  #|skinparam state {
  #|	$primary_scheme()
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|
  #|skinparam card {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $INFO
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|
  #|skinparam file {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $GRAY
  #|	FontColor $GRAY
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!if (%variable_exists("LEGACY"))
  #|!$LEGACY = "true"
  #|!endif
  #|
  #|!if (%getenv("LEGACY") == "true")
  #|!$LEGACY = "true"
  #|!endif
  #|
  #|!if (%variable_exists("$LEGACY"))
  #|
  #|skinparam useBetaStyle true
  #|
  #|!startsub mindmap
  #|
  #|<style>
  #|style mindmapDiagram {
  #|  'Padding 8
  #|  Margin 8
  #|  LineThickness 2.0
  #|  FontColor $PRIMARY_TEXT
  #|  LineColor $SECONDARY
  #|  BackGroundColor $PRIMARY_LIGHT-$PRIMARY
  #|}
  #|wbsDiagram {
  #|  'Padding 8
  #|  Margin 8
  #|  LineThickness 2.0
  #|  FontColor $PRIMARY_TEXT
  #|  LineColor $PRIMARY
  #|  BackGroundColor $PRIMARY_LIGHT-$PRIMARY
  #|}
  #|</style>
  #|!endsub
  #|!endif

///|
// name: cerulean
// display_name: Cerulean
// description: Cerulean theme based off of the bootstrap theme of the same name
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration: https://bootswatch.com/cerulean/
let builtin_theme_8 : String =
  #|
  #|!$THEME = "cerulean"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "transparent"
  #|!endif
  #|
  #|skinparam backgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|
  #|''
  #|'' Colors taken from the css file of the BS theme
  #|''
  #|!$BLUE = "#033C73"
  #|!$INDIGO = "#6610F2"
  #|!$PURPLE = "#6F42C1"
  #|!$PINK = "#E83E8C"
  #|!$RED = "#C71C22"
  #|!$ORANGE = "#FD7E14"
  #|!$YELLOW = "#DD5600"
  #|!$GREEN = "#73A839"
  #|!$TEAL = "#20C997"
  #|!$CYAN = "#2FA4E7"
  #|!$WHITE = "#FFF"
  #|!$GRAY_DARK = "#343A40"
  #|!$GRAY = "#868E96"
  #|!$PRIMARY = "#2FA4E7"
  #|!$SECONDARY = "#E9ECEF"
  #|!$SUCCESS = "#73A839"
  #|!$INFO = "#033C73"
  #|!$WARNING = "#DD5600"
  #|!$DANGER = "#C71C22"
  #|!$LIGHT = "#F8F9FA"
  #|!$DARK = "#343A40"
  #|
  #|'' *_LIGHT = tint (lighter) of the main color of 80%
  #|''          where TINT is calculated by clr + (255-clr) * tint_factor
  #|'' *_DARK = shade (darker) of the main color of 80%
  #|''          and SHADE is calculated by clr * (1 - shade_factor)
  #|''
  #|!$FGCOLOR = $DARK
  #|!$PRIMARY_LIGHT = "#59B6EC"
  #|!$PRIMARY_DARK = "#2683B9"
  #|!$PRIMARY_TEXT = $WHITE
  #|!$SECONDARY_LIGHT = "#EDF0F2"
  #|!$SECONDARY_DARK = "#BABDBF"
  #|!$SECONDARY_TEXT = $DARK
  #|!$INFO_LIGHT = "#35638F"
  #|!$INFO_DARK = "#02305C"
  #|!$INFO_TEXT = $WHITE
  #|!$SUCCESS_LIGHT = "#8FB961"
  #|!$SUCCESS_DARK = "#5C862E"
  #|!$SUCCESS_TEXT = $WHITE
  #|!$WARNING_LIGHT = "#E47833"
  #|!$WARNING_DARK = "#B14500"
  #|!$WARNING_TEXT = $WHITE
  #|!$DANGER_LIGHT = "#D2494E"
  #|!$DANGER_DARK = "#9F161B"
  #|!$DANGER_TEXT = $WHITE
  #|
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|
  #|!procedure $primary_scheme()
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY
  #|	BackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|!endprocedure
  #|''
  #|'' Style settings
  #|''
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $ORANGE
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|   Padding 15
  #|   roundcorner 20
  #|   BackgroundColor $PRIMARY-$PRIMARY_DARK
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY
  #|    FontColor $INFO
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $DARK
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|  }
  #|  nwdiagDiagram {
  #|	network {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontColor $PRIMARY_DARK
  #|	}
  #|	server {
  #|		$primary_scheme()
  #|	}
  #|	arrow {
  #|		FontColor $PRIMARY_DARK
  #|		LineColor $PRIMARY_DARK
  #|	}
  #|	group {
  #|		BackGroundColor $LIGHT
  #|		LineColor $LIGHT_DARK
  #|		LineThickness 2.0
  #|		Margin 5
  #|		Padding 5
  #|	}
  #|  }
  #|  participant {
  #|    Margin 5 40
  #|    Padding 15 20
  #|  }
  #|  ganttDiagram {
  #|	task {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		Margin 10 2 2 2
  #|		Padding 6
  #|	}
  #|	note {
  #|		FontColor $INFO_TEXT
  #|		LineColor $INFO_DARK
  #|		BackGroundColor $INFO
  #|	}
  #|	separator {
  #|		LineColor $SECONDARY
  #|		BackGroundColor $SECONDARY-$SECONDARY_DARK
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	milestone {
  #|		FontColor $INFO
  #|		FontSize 16
  #|		FontStyle italic
  #|		BackGroundColor $SECONDARY
  #|		LineColor $SECONDARY_DARK
  #|	}
  #|	timeline {
  #|		BackgroundColor $SECONDARY
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	closed {
  #|		BackgroundColor $WARNING_DARK
  #|		FontColor $WARNING_TEXT
  #|	}
  #|  }
  #|</style>
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName        "Verdana"
  #|skinparam defaultFontSize        12
  #|skinparam dpi                    100
  #|skinparam shadowing              false
  #|skinparam roundcorner            8
  #|skinparam BoxPadding             40
  #|skinparam ArrowColor             $GRAY
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_LIGHT
  #|    CBorderColor $SECONDARY_DARK
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontColor	                 $PRIMARY
  #|	BorderColor	                 $SECONDARY_DARK
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor              $SECONDARY_LIGHT-$SECONDARY
  #|}
  #|
  #|
  #|skinparam legend {
  #|	BackgroundColor $SECONDARY
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $DARK
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $WHITE-$SECONDARY_LIGHT
  #|  	DiamondBorderColor $SECONDARY_DARK
  #|	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|
  #|skinparam sequence {
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $LIGHT
  #|	BoxBorderColor $GRAY
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $SECONDARY_DARK
  #|	LifeLineBorderThickness 2
  #|	LifeLineBackgroundColor $SECONDARY_LIGHT
  #|	''
  #|	GroupBorderColor $GRAY
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO
  #|	''
  #|	DividerBackgroundColor $WHITE-$LIGHT
  #|    DividerBorderColor $GRAY
  #|    DividerBorderThickness 2
  #|    DividerFontColor $DARK
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceBorderColor $GRAY
  #|	ReferenceFontColor $DARK
  #|	ReferenceHeaderFontColor $INFO
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|
  #|skinparam control {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|
  #|skinparam entity {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|
  #|skinparam boundary {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|
  #|skinparam agent {
  #|	BackgroundColor #orange
  #|	BorderColor #999999
  #|	FontColor #333333
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $INFO_LIGHT-$INFO
  #|	BorderColor $INFO
  #|	FontColor $WHITE
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|
  #|skinparam artifact {
  #|	BackgroundColor $WHITE-$LIGHT
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|
  #|skinparam component {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|
  #|skinparam interface {
  #|	BackgroundColor  $DANGER_LIGHT
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|
  #|skinparam storage {
  #|	BackgroundColor $WARNING_LIGHT-$WARNING
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|
  #|skinparam node {
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY
  #|	BorderColor $SECONDARY
  #|	FontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|
  #|skinparam cloud {
  #|	BackgroundColor #F2FCFE-#eeeeee
  #|	BorderColor #F2FCFE
  #|	FontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|
  #|skinparam database {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|
  #|skinparam class {
  #|	$primary_scheme()
  #|	HeaderBackgroundColor $PRIMARY-$PRIMARY_DARK
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $LIGHT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|
  #|skinparam rectangle {
  #|	FontColor $PRIMARY
  #|	BorderColor $PRIMARY_LIGHT
  #|	BackgroundColor $BGCOLOR
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|
  #|skinparam package {
  #|	FontColor $PRIMARY
  #|	BorderColor $PRIMARY_LIGHT
  #|	BackgroundColor $BGCOLOR
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|
  #|skinparam folder {
  #|	BackgroundColor $WHITE-$SECONDARY_LIGHT
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|
  #|skinparam frame {
  #|	BackgroundColor $WHITE-$SECONDARY_LIGHT
  #|  	BorderColor $INFO
  #|	FontColor $INFO
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|
  #|skinparam state {
  #|	$primary_scheme()
  #|	BorderColor $PRIMARY_DARK
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|
  #|skinparam card {
  #|	BackgroundColor $INFO_LIGHT-$INFO
  #|	BorderColor $INFO
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|
  #|skinparam file {
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY
  #|	BorderColor $INFO
  #|	FontColor $GRAY
  #|
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub

///|
// name: cloudscape-design
// display_name: Cloudscape design
// description: Theme based off of the colors used by Cloudscape design
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration: https://cloudscape.design/foundation/visual-foundation/data-vis-colors/
let builtin_theme_9 : String =
  #|
  #|'!$PUML_OUTLINE = "true"
  #|'!$PUML_BGCOLOR = "#0f1b2a"
  #|'!$PUML_MODE = "dark"
  #|!$PUML_THEME = "cloudscape-design"
  #|!$THEME      = "cloudscape-design"
  #|''
  #|'' User can specify the PUML_BGCOLOR via command line or set this variable before
  #|'' loading this theme file. PUML_BGCOLOR is the background color of the image that is
  #|'' generated by plantuml
  #|''
  #|!if %not(%variable_exists("$PUML_BGCOLOR"))
  #|    !$PUML_BGCOLOR = "transparent"
  #|!endif
  #|''
  #|'' If no gradient is given, default to 20
  #|''
  #|!if %not(%variable_exists("$PUML_GRADIENT"))
  #|    !$PUML_GRADIENT = 20
  #|!endif
  #|''
  #|'' User can specify the PUML_MODE via command line or set this variable before
  #|'' loading this theme file. PUML_MODE is either 'light' PUML_MODE or 'dark' PUML_MODE.
  #|''
  #|!if %not(%variable_exists("$PUML_MODE"))
  #|    !$PUML_MODE = "light"
  #|!endif
  #|''
  #|'' User can specify the PUML_OUTLINE via command line or set this variable before
  #|'' loading this theme file. PUML_OUTLINE is either 'true' or 'false'.
  #|''
  #|!if %not(%variable_exists("$PUML_OUTLINE"))
  #|    !$PUML_OUTLINE = "false"
  #|!endif
  #|''
  #|skinparam BackgroundColor $PUML_BGCOLOR
  #|skinparam useBetaStyle false
  #|!$ALPHA = "80"
  #|''
  #|'' Supplementary Colors
  #|''
  #|!$WHITE      = "#FFF"
  #|!$GRAY_LIGHT = "#222"
  #|!$GRAY       = "#868e96"
  #|!$PRIMARY    = "#0972d3"
  #|!$WARNING    = "#ecdd00"
  #|!$LIGHT      = "#d1d5db"
  #|!$DARK       = "#000716"
  #|!$SECONDARY_TEXT = "#539fe5"
  #|''
  #|'' define colors based on PUML_MODE
  #|''
  #|!if ($PUML_MODE == "light")
  #|    !$PRIMARY_TEXT    = $LIGHT
  #|    !$SECONDARY       = "#eeeeee"
  #|    !$SECONDARY_LIGHT = %lighten($SECONDARY, $PUML_GRADIENT)
  #|    !$SUCCESS         = "#037f0c"
  #|    !$INFO            = "#0972d3"
  #|    !$DANGER          = "#d91515"
  #|    !$SECONDARY_TEXT  = $DARK
  #|    !$FGCOLOR         = $DARK
  #|    !$DIAMOND_BD      = %darken($SECONDARY, $PUML_GRADIENT)
  #|    !$GRAY_LIGHT      = %lighten($GRAY, $PUML_GRADIENT)
  #|    !$GRAY_DARK       = %darken($GRAY, $PUML_GRADIENT)
  #|	!$MAIN_BG         = $WHITE
  #|    ''
  #|    '' Assume if the background is transparent, that the
  #|    '' background will be dark for this theme
  #|    ''
  #|    !assume transparent light
  #|!else
  #|    !$TMP             = $LIGHT
  #|    !$LIGHT           = $DARK
  #|    !$DARK            = $TMP
  #|    !$PRIMARY         = "#539fe5"
  #|    !$PRIMARY_TEXT    = $WHITE
  #|    !$SECONDARY       = "#2a2e33"
  #|    !$SECONDARY_LIGHT = %lighten($SECONDARY, $PUML_GRADIENT)
  #|    !$SUCCESS         = "#037f0c"
  #|    !$INFO            = "#0972d3"
  #|    !$DANGER          = "#ff5d64"
  #|	!$WARNING         = "#fbf8cc"
  #|    !$SECONDARY_TEXT  = $WHITE
  #|    !$FGCOLOR         = $WHITE
  #|    !$DIAMOND_BD      = %lighten($SECONDARY, $PUML_GRADIENT)
  #|    !$GRAY_LIGHT      = %darken($GRAY, $PUML_GRADIENT)
  #|    !$GRAY_DARK       = %lighten($GRAY, $PUML_GRADIENT)
  #|	!$MAIN_BG         = "#0f1b2a"
  #|    ''
  #|    '' Assume if the background is transparent, that the
  #|    '' background will be dark for this theme
  #|    ''
  #|    !assume transparent dark
  #|!endif
  #|''
  #|'' *_DARK = tint (lighter) of the main color
  #|'' *_LIGHT = shade (darker) of the main color
  #|''
  #|!$PRIMARY_DARK    = %darken($PRIMARY, $PUML_GRADIENT)
  #|!$PRIMARY_LIGHT   = %lighten($PRIMARY, $PUML_GRADIENT)
  #|!$SECONDARY_DARK  = %darken($SECONDARY, $PUML_GRADIENT)
  #|!$SUCCESS_DARK    = %darken($SUCCESS, $PUML_GRADIENT)
  #|!$SUCCESS_LIGHT   = %lighten($SUCCESS, $PUML_GRADIENT)
  #|!$INFO_DARK       = %darken($INFO, $PUML_GRADIENT)
  #|!$INFO_LIGHT      = %lighten($INFO, $PUML_GRADIENT)
  #|!$DANGER_DARK     = %darken($DANGER, $PUML_GRADIENT)
  #|!$DANGER_LIGHT    = %lighten($DANGER, $PUML_GRADIENT)
  #|!$WARNING_DARK    = %darken($WARNING, $PUML_GRADIENT)
  #|!$WARNING_LIGHT   = %lighten($WARNING, $PUML_GRADIENT)
  #|!$DARK_DARK       = %darken($DARK, $PUML_GRADIENT)
  #|!$DARK_LIGHT      = %lighten($DARK, $PUML_GRADIENT)
  #|!$LIGHT_DARK      = %darken($LIGHT, $PUML_GRADIENT)
  #|!$LIGHT_LIGHT     = %lighten($LIGHT, $PUML_GRADIENT)
  #|''
  #|'' Set text colors
  #|''
  #|!$INFO_TEXT    = $WHITE
  #|!$SUCCESS_TEXT = $WHITE
  #|!$WARNING_TEXT = $WHITE
  #|!$DANGER_TEXT  = $WHITE
  #|!$HEADER_TEXT  = $WHITE
  #|''
  #|!if ($PUML_OUTLINE == "true")
  #|	!$HEADER_TEXT  = $PRIMARY_TEXT
  #|	!$PRIMARY_TEXT = $PRIMARY_LIGHT
  #|	!$INFO_TEXT    = $INFO
  #|	!$WARNING_TEXT = $WARNING_LIGHT
  #|	!$DARK_BG      = $PUML_BGCOLOR
  #|	!$INFO_BG      = $PUML_BGCOLOR
  #|	!$DANGER_BG    = $PUML_BGCOLOR
  #|	!$WARNING_BG   = $PUML_BGCOLOR
  #|	!$SECONDARY_BG = $PUML_BGCOLOR
  #|!else
  #|	!$DARK_BG      = $DARK
  #|	!$INFO_BG      = $INFO
  #|	!$DANGER_BG    = $DANGER
  #|	!$WARNING_BG   = $WARNING
  #|	!$SECONDARY_BG = $SECONDARY
  #|!endif
  #|!unquoted function $alpha($color, $alpha) !return $color + $alpha
  #|''
  #|'' Called to make the text in the color of SUCCESS
  #|''
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|''
  #|'' Called to make the text in the color of DANGER
  #|''
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|''
  #|'' Called to make the text in the color of WARNING
  #|''
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|''
  #|'' Called to use the primary color scheme
  #|'' Different colors based on if PUML_OUTLINE
  #|'' is true or not
  #|''
  #|!procedure $primary_scheme()
  #|	!if ($PUML_OUTLINE == "true")
  #|		FontColor $PRIMARY
  #|		BorderColor $PRIMARY
  #|		BackgroundColor $PUML_BGCOLOR
  #|	!else
  #|		FontColor $PRIMARY_TEXT
  #|		BorderColor $PRIMARY
  #|		BackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|	!endif
  #|!endprocedure
  #|''
  #|'' Called to use the secondary color scheme
  #|''
  #|!procedure $secondary_scheme()
  #|	!if ($PUML_OUTLINE == "true")
  #|		FontColor $SECONDARY_DARK
  #|		BorderColor $SECONDARY_DARK
  #|		BackgroundColor $PUML_BGCOLOR
  #|	!else
  #|		FontColor $SECONDARY_TEXT
  #|		BorderColor $SECONDARY_DARK
  #|		BackgroundColor $SECONDARY_LIGHT-$SECONDARY
  #|	!endif
  #|!endprocedure
  #|''
  #|'' HTTP Methods
  #|''
  #|!_POST   = "<color #007a3e>POST</color>"
  #|!_PUT    = "<color #ea7400>PUT</color>"
  #|!_DELETE = "<color #cf2a2a>DELETE</color>"
  #|!_GET    = "<color #009fdb>GET</color>"
  #|!_PATCH  = "<color #b5bd00>PATCH</color>"
  #|!_HEAD   = "<color #9012fe>HEAD</color>"
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName       "Verdana"
  #|skinparam defaultFontSize       12
  #|skinparam dpi                   100
  #|skinparam shadowing             false
  #|skinparam roundcorner           8
  #|skinparam BoxPadding            40
  #|skinparam ArrowColor            $DARK
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_LIGHT
  #|    CBorderColor $SECONDARY_DARK
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|}
  #|
  #|skinparam legend {
  #|    $secondary_scheme()
  #|    BackgroundColor transparent
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $SECONDARY_BG
  #|  	DiamondBorderColor $DIAMOND_BD
  #|  	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|skinparam actor {
  #|	$primary_scheme()
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|skinparam arrow {
  #|	Thickness 2
  #|	Color $GRAY_LIGHT
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|skinparam sequence {
  #|	ArrowThickness 2
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $PRIMARY
  #|	BackgroundColor $PUML_BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $alpha($PUML_BGCOLOR, $ALPHA)
  #|	BoxBorderColor $GRAY_DARK
  #|	BoxFontColor $GRAY_DARK
  #|	''
  #|	DelayFontColor $LIGHT
  #|	''
  #|	LifeLineBorderColor $PRIMARY
  #|	LifeLineBorderThickness 0
  #|	LifeLineBackgroundColor $SECONDARY
  #|	''
  #|	GroupBorderColor $DARK
  #|	GroupBorderThickness 1
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO
  #|	GroupBackgroundColor $alpha($SECONDARY, $ALPHA)
  #|	GroupBodyBackgroundColor $alpha($PUML_BGCOLOR, $ALPHA)
  #|	GroupHeaderBackgroundColor $PUML_BGCOLOR
  #|	''
  #|	DividerBackgroundColor $SECONDARY
  #|	DividerBorderColor $SECONDARY_LIGHT
  #|    	DividerBorderThickness 2
  #|    	DividerFontColor $DARK
  #|	''
  #|	ReferenceAlignment left
  #|	ReferenceBackgroundColor $alpha($PUML_BGCOLOR, $ALPHA)
  #|	ReferenceBorderColor $SECONDARY
  #|	ReferenceBorderThickness 2
  #|	ReferenceFontColor $DARK
  #|	ReferenceHeaderFontColor $INFO
  #|	ReferenceHeaderBackgroundColor $alpha($SECONDARY, $ALPHA)
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|	StereotypeFontSize 12
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BackgroundColor $PUML_BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|skinparam control {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|skinparam entity {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|skinparam boundary {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|skinparam agent {
  #|	BackgroundColor $WARNING
  #|	BorderColor $WARNING_LIGHT
  #|	FontColor $GRAY
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $INFO_BG
  #|	BorderColor $INFO
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|skinparam artifact {
  #|	BackgroundColor $DARK_BG
  #|	BorderColor $DARK_DARK
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|skinparam component {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|skinparam interface {
  #|	BackgroundColor  $DANGER_DARK
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|skinparam storage {
  #|	BackgroundColor $WARNING_BG
  #|  	BorderColor $WARNING_DARK
  #|	FontColor $GRAY
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|skinparam node {
  #|	BackgroundColor  $PUML_BGCOLOR
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|skinparam cloud {
  #|	BackgroundColor transparent
  #|	BorderColor $DARK
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|skinparam database {
  #|	$primary_scheme()
  #|	FontColor $FGCOLOR
  #|	StereotypeFontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|skinparam class {
  #|	$primary_scheme()
  #|	FontColor $HEADER_TEXT
  #|	HeaderBackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $PRIMARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $PRIMARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|skinparam rectangle {
  #|	BackgroundColor $PUML_BGCOLOR
  #|	FontColor $SECONDARY_TEXT
  #|	BorderColor $SECONDARY_TEXT
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|skinparam package {
  #|	BackgroundColor $PUML_BGCOLOR
  #|  	BorderColor $SECONDARY_TEXT
  #|	FontColor $SECONDARY_TEXT
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|skinparam folder {
  #|	BackgroundColor $SECONDARY_BG
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|skinparam frame {
  #|	BackgroundColor $SECONDARY_BG
  #|  	BorderColor $INFO
  #|	FontColor $INFO
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|skinparam state {
  #|	$primary_scheme()
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|skinparam card {
  #|	BackgroundColor $INFO_BG
  #|	BorderColor $INFO_DARK
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|skinparam file {
  #|	BackgroundColor $SECONDARY_BG
  #|	BorderColor $LIGHT
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|
  #|!startsub map
  #|skinparam map {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|''
  #|'' When mixing skinparam and <style>, it is very important to put <style> after skinparam
  #|''
  #|'' Style settings
  #|''
  #|<style>
  #|participant {
  #|  Margin 5 40
  #|  Padding 15 20
  #|}
  #|wbsDiagram, mindmapDiagram {
  #|  root {
  #|    BackgroundColor $PUML_BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $INFO_BG
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|    $primary_scheme()
  #|    Padding 15
  #|    RoundCorner 20
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY_BG
  #|    FontColor $INFO_BG
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $PUML_BGCOLOR
  #|    FontColor $DARK_BG
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $PUML_BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $SECONDARY_LIGHT-$SECONDARY_BG
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $SECONDARY_BG
  #|  }
  #|}
  #|nwdiagDiagram {
  #|  network {
  #|    $primary_scheme()
  #|    LineColor $PRIMARY_BG
  #|    LineThickness 1.0
  #|    FontColor $PRIMARY_DARK
  #|  }
  #|  server {
  #|    $primary_scheme()
  #|  }
  #|  arrow {
  #|    FontColor $PRIMARY_DARK
  #|    LineColor $PRIMARY_DARK
  #|  }
  #|  group {
  #|    BackGroundColor $LIGHT_BG
  #|    LineColor $LIGHT_DARK
  #|    LineThickness 2.0
  #|    Margin 5
  #|    Padding 5
  #|  }
  #|}
  #|ganttDiagram {
  #|  task {
  #|    $primary_scheme()
  #|	LineColor $PRIMARY_BG
  #|    Margin 10 2 2 2
  #|    Padding 6
  #|  }
  #|  note {
  #|	FontColor $INFO_TEXT
  #|	LineColor $INFO_DARK
  #|    BackGroundColor $INFO_BG
  #|  }
  #|  separator {
  #|	LineColor $SECONDARY_BG
  #|    BackGroundColor $secondary_scheme()
  #|    FontColor $SECONDARY_TEXT
  #|  }
  #|  milestone {
  #|	FontColor $INFO_BG
  #|	FontSize 16
  #|	FontStyle italic
  #|	BackGroundColor $DIAMOND_BG
  #|	LineColor $SECONDARY_DARK
  #|  }
  #|  timeline {
  #|    BackgroundColor $SECONDARY_BG
  #|    FontColor $SECONDARY_TEXT
  #|  }
  #|  closed {
  #|	BackgroundColor $WARNING_DARK
  #|	FontColor $WARNING_TEXT
  #|  }
  #|}
  #|</style>
  #|

///|
// name: crt-amber
// display_name: Cathode-ray tube (CRT) amber
// description: An orange on black theme based on monochrome CRT monitors
// author: Matthew Leather
// release:
// license:
// version:
// source:
// inspiration: https://superuser.com/a/1206781
let builtin_theme_10 : String =
  #|
  #|!$THEME = "crt-amber"
  #|
  #|!$DARK_AMBER  = "#FFB000"
  #|!$LIGHT_AMBER = "#FFCC00"
  #|
  #|!$BGCOLOR = "#282828"
  #|!$FGCOLOR = $DARK_AMBER
  #|
  #|!ifndef $FONT_NAME
  #|  !$FONT_NAME = "Verdana"
  #|!endif
  #|
  #|!ifndef $FONT_NAME_MONOSPACED
  #|  !$FONT_NAME_MONOSPACED = "Courier"
  #|!endif
  #|
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $FGCOLOR
  #|    FontName $FONT_NAME
  #|    HyperLinkColor $LIGHT_AMBER
  #|    LineColor $FGCOLOR
  #|    LineThickness 1
  #|    Margin 5
  #|  }
  #|  box {
  #|    LineStyle 12-18
  #|    LineThickness 3
  #|  }
  #|  document {
  #|    caption {
  #|      LineThickness 0
  #|    }
  #|    footer {
  #|      LineThickness 0
  #|    }
  #|    header {
  #|      LineThickness 0
  #|    }
  #|    title {
  #|      FontSize 22
  #|      LineThickness 0
  #|    }
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  node {
  #|    MaximumWidth 300
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  participant {
  #|    Margin 5 10
  #|    Padding 5 5
  #|  }
  #|</style>
  #|
  #|skinparam ArrowLollipopColor $FGCOLOR
  #|skinparam BackgroundColor $BGCOLOR
  #|skinparam DefaultFontName $FONT_NAME
  #|skinparam DefaultMonospacedFontName $FONT_NAME_MONOSPACED
  #|skinparam LifelineStrategy solid
  #|skinparam SequenceLifeLineBorderColor $FGCOLOR
  #|skinparam Shadowing false
  #|skinparam UseBetaStyle true
  #|
  #|skinparam Activity {
  #|  BackgroundColor $BGCOLOR
  #|  BarColor $FGCOLOR
  #|  BorderColor $FGCOLOR
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Boundary {
  #|  FontColor $FGCOLOR
  #|}
  #|skinparam Box {
  #|  Padding 5
  #|}
  #|skinparam CircledCharacter {
  #|  FontColor $BGCOLOR
  #|  FontName $FONT_NAME_MONOSPACED
  #|  Radius 9
  #|}
  #|skinparam Class {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam ClassAttribute {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam ClassStereotype {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Footer {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Header {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Hyperlink {
  #|  Color $LIGHT_AMBER
  #|}
  #|skinparam IconPackage {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam IconPrivate {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam IconProtected {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam IconPublic {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam Note {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Object {
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam Package {
  #|  BorderColor $FGCOLOR
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam State {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeA {
  #|  BackgroundColor $FGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeC {
  #|  BackgroundColor $FGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeE {
  #|  BackgroundColor $FGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeI {
  #|  BackgroundColor $FGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeN {
  #|  BackgroundColor $FGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam UseCaseStereoType {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}

///|
// name: crt-green
// display_name: Cathode-ray tube (CRT) green
// description: A green on black theme based on monochrome CRT monitors
// author: Matthew Leather
// release:
// license:
// version:
// source:
// inspiration: https://superuser.com/a/1206781
let builtin_theme_11 : String =
  #|
  #|!$THEME = "crt-green"
  #|
  #|!$BGCOLOR = "#282828"
  #|!$FGCOLOR = "#33FF33"
  #|
  #|!ifndef $FONT_NAME
  #|  !$FONT_NAME = "Verdana"
  #|!endif
  #|
  #|!ifndef $FONT_NAME_MONOSPACED
  #|  !$FONT_NAME_MONOSPACED = "Courier"
  #|!endif
  #|
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $FGCOLOR
  #|    FontName $FONT_NAME
  #|    HyperLinkColor $FGCOLOR
  #|    LineColor $FGCOLOR
  #|    LineThickness 1
  #|    Margin 5
  #|  }
  #|  box {
  #|    LineStyle 12-18
  #|    LineThickness 3
  #|  }
  #|  document {
  #|    caption {
  #|      LineThickness 0
  #|    }
  #|    footer {
  #|      LineThickness 0
  #|    }
  #|    header {
  #|      LineThickness 0
  #|    }
  #|    title {
  #|      FontSize 22
  #|      LineThickness 0
  #|    }
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  node {
  #|    MaximumWidth 300
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  participant {
  #|    Margin 5 10
  #|    Padding 5 5
  #|  }
  #|</style>
  #|
  #|skinparam ArrowLollipopColor $FGCOLOR
  #|skinparam BackgroundColor $BGCOLOR
  #|skinparam DefaultFontName $FONT_NAME
  #|skinparam DefaultMonospacedFontName $FONT_NAME_MONOSPACED
  #|skinparam LifelineStrategy solid
  #|skinparam SequenceLifeLineBorderColor $FGCOLOR
  #|skinparam Shadowing false
  #|skinparam UseBetaStyle true
  #|
  #|skinparam Activity {
  #|  BackgroundColor $BGCOLOR
  #|  BarColor $FGCOLOR
  #|  BorderColor $FGCOLOR
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Boundary {
  #|  FontColor $FGCOLOR
  #|}
  #|skinparam Box {
  #|  Padding 5
  #|}
  #|skinparam CircledCharacter {
  #|  FontColor $BGCOLOR
  #|  FontName $FONT_NAME_MONOSPACED
  #|  Radius 9
  #|}
  #|skinparam Class {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam ClassAttribute {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam ClassStereotype {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Footer {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Header {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Hyperlink {
  #|  Color $FGCOLOR
  #|}
  #|skinparam IconPackage {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam IconPrivate {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam IconProtected {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam IconPublic {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam Note {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Object {
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam Package {
  #|  BorderColor $FGCOLOR
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam State {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeA {
  #|  BackgroundColor $FGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeC {
  #|  BackgroundColor $FGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeE {
  #|  BackgroundColor $FGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeI {
  #|  BackgroundColor $FGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeN {
  #|  BackgroundColor $FGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam UseCaseStereoType {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}

///|
// name: cyborg-outline
// display_name: Cyborg Outline
// description: Theme based off of the bootstrap theme of the same name, with outline colors
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration: https://bootswatch.com/cyborg/
let builtin_theme_12 : String =
  #|
  #|!$THEME = "cyborg-outline"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "transparent"
  #|!endif
  #|
  #|skinparam backgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|
  #|''
  #|'' Colors taken from the css file of the BS theme
  #|''
  #|!$BLUE = "#2A9FD6"
  #|!$INDIGO = "#6610f2"
  #|!$PURPLE = "#6f42c1"
  #|!$PINK = "#e83e8c"
  #|!$RED = "#CC0000"
  #|!$ORANGE = "#fd7e14"
  #|!$YELLOW = "#FF8800"
  #|!$GREEN = "#77B300"
  #|!$TEAL = "#20c997"
  #|!$CYAN = "#9933CC"
  #|!$WHITE = "#FFF"
  #|!$GRAY_LIGHT = "#222"
  #|!$GRAY = "#555"
  #|!$PRIMARY = "#2A9FD6"
  #|!$SECONDARY = "#555"
  #|!$SUCCESS = "#77B300"
  #|!$INFO = "#9933CC"
  #|!$WARNING = "#FF8800"
  #|!$DANGER = "#CC0000"
  #|!$LIGHT = "#222"
  #|!$DARK = "#ADAFAE"
  #|
  #|'' *_DARK = tint (lighter) of the main color of 80%
  #|''          where TINT is calculated by clr + (255-clr) * tint_factor
  #|'' *_LIGHT = shade (darker) of the main color of 80%
  #|''          and SHADE is calculated by clr * (1 - shade_factor)
  #|''
  #|!$FGCOLOR = $WHITE
  #|!$PRIMARY_DARK = "#55B2DE"
  #|!$PRIMARY_LIGHT = "#227FAB"
  #|!$PRIMARY_TEXT = $PRIMARY
  #|!$SECONDARY_DARK = "#777777"
  #|!$SECONDARY_LIGHT = "#444444"
  #|!$SECONDARY_TEXT = $SECONDARY_DARK
  #|!$INFO_DARK = "#AD5CD6"
  #|!$INFO_LIGHT = "#7a29a3"
  #|!$INFO_TEXT = $INFO
  #|!$SUCCESS_DARK = "#92C233"
  #|!$SUCCESS_LIGHT = "#5F8F00"
  #|!$SUCCESS_TEXT = $SUCCESS
  #|!$WARNING_DARK = "#FFA033"
  #|!$WARNING_LIGHT = "#cc6d00"
  #|!$WARNING_TEXT = $WARNING
  #|!$DANGER_DARK = "#D63333"
  #|!$DANGER_LIGHT = "#a30000"
  #|!$DANGER_TEXT = $WHITE
  #|!$DARK_DARK = "#BDBFBE"
  #|!$DARK_LIGHT = "#8A8C8B"
  #|!$LIGHT_DARK = "#4E4E4E"
  #|!$LIGHT_LIGHT = "#1B1B1B"
  #|
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|
  #|!procedure $primary_scheme()
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY_DARK
  #|	BackgroundColor $BGCOLOR
  #|!endprocedure
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $ORANGE
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|   Padding 15
  #|   roundcorner 20
  #|   BackgroundColor $BGCOLOR
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY
  #|    FontColor $INFO
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $DARK
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $BGCOLOR
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|  }
  #|  nwdiagDiagram {
  #|	network {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontColor $PRIMARY_LIGHT
  #|	}
  #|	server {
  #|		$primary_scheme()
  #|	}
  #|	arrow {
  #|		FontColor $PRIMARY_LIGHT
  #|		LineColor $PRIMARY_LIGHT
  #|	}
  #|	group {
  #|		BackGroundColor $LIGHT
  #|		LineColor $LIGHT_DARK
  #|		LineThickness 2.0
  #|		Margin 5
  #|		Padding 5
  #|	}
  #|  }
  #|  participant {
  #|    Margin 5 40
  #|    Padding 15 20
  #|  }
  #|  ganttDiagram {
  #|	task {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		Margin 10 2 2 2
  #|		Padding 6
  #|	}
  #|	note {
  #|		FontColor $INFO_TEXT
  #|		LineColor $INFO_DARK
  #|		BackGroundColor $BGCOLOR
  #|	}
  #|	separator {
  #|		LineColor $SECONDARY_DARK
  #|		BackGroundColor $BGCOLOR
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	milestone {
  #|		FontColor $INFO
  #|		FontSize 16
  #|		FontStyle italic
  #|		BackGroundColor $SECONDARY
  #|		LineColor $SECONDARY_DARK
  #|	}
  #|	timeline {
  #|		BackgroundColor $SECONDARY
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	closed {
  #|		BackgroundColor $WARNING_DARK
  #|		FontColor $WARNING_TEXT
  #|	}
  #|  }
  #|</style>
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName       "Verdana"
  #|skinparam defaultFontSize       12
  #|skinparam dpi                   100
  #|skinparam shadowing             false
  #|skinparam roundcorner           8
  #|skinparam BoxPadding            40
  #|skinparam ArrowColor            $DARK
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_DARK
  #|    CBorderColor $SECONDARY_LIGHT
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontColor	                 $PRIMARY
  #|	BorderColor	                 $SECONDARY_DARK
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor              $BGCOLOR
  #|}
  #|
  #|skinparam legend {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $DARK
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $BGCOLOR
  #|  	DiamondBorderColor $SECONDARY_DARK
  #|  	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	$primary_scheme()
  #|	FontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|
  #|skinparam sequence {
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $BGCOLOR
  #|	BoxBorderColor $DARK
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $SECONDARY
  #|	LifeLineBorderThickness 2
  #|	LifeLineBackgroundColor $BGCOLOR
  #|	''
  #|	GroupBorderColor $DARK
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO_TEXT
  #|	GroupBackgroundColor $BGCOLOR
  #|	GroupHeaderBackgroundColor $BGCOLOR
  #|	''
  #|	DividerBackgroundColor $BGCOLOR
  #|    DividerBorderColor $DARK
  #|    DividerBorderThickness 2
  #|    DividerFontColor $DARK
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceBorderColor $DARK
  #|	ReferenceFontColor $DARK
  #|	ReferenceHeaderFontColor $INFO_TEXT
  #|	ReferenceHeaderBackgroundColor $BGCOLOR
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|
  #|skinparam control {
  #|	$primary_scheme()
  #|	FontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|
  #|skinparam entity {
  #|	$primary_scheme()
  #|	FontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|
  #|skinparam boundary {
  #|	$primary_scheme()
  #|	FontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|
  #|skinparam agent {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $WARNING_LIGHT
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $INFO_DARK
  #|	FontColor $INFO_DARK
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|
  #|skinparam artifact {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $DARK_DARK
  #|	FontColor $DARK_DARK
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|
  #|skinparam component {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|
  #|skinparam interface {
  #|	BackgroundColor  $BGCOLOR
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|
  #|skinparam storage {
  #|	BackgroundColor $BGCOLOR
  #|  	BorderColor $WARNING_DARK
  #|	FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|
  #|skinparam node {
  #|	BackgroundColor  $BGCOLOR
  #|	BorderColor $DARK
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|
  #|skinparam cloud {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor #F2FCFE
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|
  #|skinparam database {
  #|	$primary_scheme()
  #|	FontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|
  #|!startsub class
  #|
  #|skinparam class {
  #|	$primary_scheme()
  #|        FontColor $LIGHT
  #|	HeaderBackgroundColor $PRIMARY_LIGHT
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $DARK
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $SECONDARY_DARK
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|
  #|skinparam rectangle {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|
  #|skinparam package {
  #|	BackgroundColor $BGCOLOR
  #|  	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|
  #|skinparam folder {
  #|	BackgroundColor $BGCOLOR
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|
  #|skinparam frame {
  #|	BackgroundColor $BGCOLOR
  #|  	BorderColor $INFO
  #|	FontColor $INFO_TEXT
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|
  #|skinparam state {
  #|	$primary_scheme()
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|
  #|skinparam card {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $INFO
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|
  #|skinparam file {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $GRAY
  #|	FontColor $GRAY
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub

///|
// name: cyborg
// display_name: Cyborg
// description: Theme based off of the bootstrap theme of the same name
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration: https://bootswatch.com/cyborg/
let builtin_theme_13 : String =
  #|
  #|!$THEME = "cyborg"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "transparent"
  #|!endif
  #|
  #|skinparam backgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|
  #|''
  #|'' Colors taken from the css file of the BS theme
  #|''
  #|!$BLUE = "#2A9FD6"
  #|!$INDIGO = "#6610f2"
  #|!$PURPLE = "#6f42c1"
  #|!$PINK = "#e83e8c"
  #|!$RED = "#CC0000"
  #|!$ORANGE = "#fd7e14"
  #|!$YELLOW = "#FF8800"
  #|!$GREEN = "#77B300"
  #|!$TEAL = "#20c997"
  #|!$CYAN = "#9933CC"
  #|!$WHITE = "#FFF"
  #|!$GRAY_LIGHT = "#222"
  #|!$GRAY = "#555"
  #|!$PRIMARY = "#2A9FD6"
  #|!$SECONDARY = "#555"
  #|!$SUCCESS = "#77B300"
  #|!$INFO = "#9933CC"
  #|!$WARNING = "#FF8800"
  #|!$DANGER = "#CC0000"
  #|!$LIGHT = "#222"
  #|!$DARK = "#ADAFAE"
  #|
  #|'' *_DARK = tint (lighter) of the main color of 80%
  #|''          where TINT is calculated by clr + (255-clr) * tint_factor
  #|'' *_LIGHT = shade (darker) of the main color of 80%
  #|''          and SHADE is calculated by clr * (1 - shade_factor)
  #|''
  #|!$FGCOLOR = $WHITE
  #|!$PRIMARY_DARK = "#55B2DE"
  #|!$PRIMARY_LIGHT = "#227FAB"
  #|!$PRIMARY_TEXT = $WHITE
  #|!$SECONDARY_DARK = "#777777"
  #|!$SECONDARY_LIGHT = "#444444"
  #|!$SECONDARY_TEXT = $WHITE
  #|!$INFO_DARK = "#AD5CD6"
  #|!$INFO_LIGHT = "#9F161B"
  #|!$INFO_TEXT = $WHITE
  #|!$SUCCESS_DARK = "#92C233"
  #|!$SUCCESS_LIGHT = "#5F8F00"
  #|!$SUCCESS_TEXT = $WHITE
  #|!$WARNING_DARK = "#FFA033"
  #|!$WARNING_LIGHT = "#CC6D00"
  #|!$WARNING_TEXT = $WHITE
  #|!$DANGER_DARK = "#D63333"
  #|!$DANGER_LIGHT = "#A30000"
  #|!$DANGER_TEXT = $WHITE
  #|!$DARK_DARK = "#BDBFBE"
  #|!$DARK_LIGHT = "#8A8C8B"
  #|!$LIGHT_DARK = "#4E4E4E"
  #|!$LIGHT_LIGHT = "#1B1B1B"
  #|
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|
  #|!procedure $primary_scheme()
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY_DARK
  #|	BackgroundColor $PRIMARY
  #|!endprocedure
  #|''
  #|'' Style settings
  #|''
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $ORANGE
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|   Padding 15
  #|   roundcorner 20
  #|   BackgroundColor $PRIMARY-$PRIMARY_DARK
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY
  #|    FontColor $INFO
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $DARK
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|  }
  #|  nwdiagDiagram {
  #|	network {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontColor $PRIMARY_LIGHT
  #|	}
  #|	server {
  #|		$primary_scheme()
  #|	}
  #|	arrow {
  #|		FontColor $PRIMARY_LIGHT
  #|		LineColor $PRIMARY_LIGHT
  #|	}
  #|	group {
  #|		BackGroundColor $LIGHT
  #|		LineColor $LIGHT_DARK
  #|		LineThickness 2.0
  #|		Margin 5
  #|		Padding 5
  #|	}
  #|  }
  #|  participant {
  #|    Margin 5 40
  #|    Padding 15 20
  #|  }
  #|  ganttDiagram {
  #|	task {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		Margin 10 2 2 2
  #|		Padding 6
  #|	}
  #|	note {
  #|		FontColor $INFO_TEXT
  #|		LineColor $INFO_DARK
  #|		BackGroundColor $INFO
  #|	}
  #|	separator {
  #|		LineColor $SECONDARY
  #|		BackGroundColor $SECONDARY-$SECONDARY_DARK
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	milestone {
  #|		FontColor $INFO
  #|		FontSize 16
  #|		FontStyle italic
  #|		BackGroundColor $SECONDARY
  #|		LineColor $SECONDARY_DARK
  #|	}
  #|	timeline {
  #|		BackgroundColor $SECONDARY
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	closed {
  #|		BackgroundColor $WARNING_DARK
  #|		FontColor $WARNING_TEXT
  #|	}
  #|  }
  #|</style>
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName       "Verdana"
  #|skinparam defaultFontSize       12
  #|skinparam dpi                   100
  #|skinparam shadowing             false
  #|skinparam roundcorner           8
  #|skinparam BoxPadding            40
  #|skinparam ArrowColor            $DARK
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_DARK
  #|    CBorderColor $SECONDARY_LIGHT
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontColor	                 $PRIMARY
  #|	BorderColor	                 $SECONDARY_DARK
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor              $SECONDARY_LIGHT-$SECONDARY
  #|}
  #|
  #|
  #|skinparam legend {
  #|	BackgroundColor $SECONDARY
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $DARK
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $SECONDARY_LIGHT
  #|  	DiamondBorderColor $SECONDARY_DARK
  #|  	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	$primary_scheme()
  #|	FontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|
  #|skinparam sequence {
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $BGCOLOR
  #|	BoxBorderColor $DARK
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $SECONDARY
  #|	LifeLineBorderThickness 2
  #|	LifeLineBackgroundColor $SECONDARY_DARK
  #|	''
  #|	GroupBorderColor $SECONDARY
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO
  #|	GroupBackgroundColor $SECONDARY
  #|	GroupHeaderBackgroundColor $BGCOLOR
  #|	''
  #|	DividerBackgroundColor $DARK
  #|    DividerBorderColor $DARK
  #|    DividerBorderThickness 2
  #|    DividerFontColor $LIGHT
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceBorderColor $SECONDARY
  #|	ReferenceFontColor $SECONDARY_TEXT
  #|	ReferenceHeaderBackgroundColor $SECONDARY
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|
  #|skinparam control {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|
  #|skinparam entity {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|
  #|skinparam boundary {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|
  #|skinparam agent {
  #|	BackgroundColor $WARNING
  #|	BorderColor $WARNING_LIGHT
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $INFO
  #|	BorderColor $INFO_DARK
  #|	FontColor $WHITE
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|
  #|skinparam artifact {
  #|	BackgroundColor $DARK
  #|	BorderColor $DARK_DARK
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|
  #|skinparam component {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|
  #|skinparam interface {
  #|	BackgroundColor  $DANGER_DARK
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|
  #|skinparam storage {
  #|	BackgroundColor $WARNING
  #|  	BorderColor $WARNING_DARK
  #|	FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|
  #|skinparam node {
  #|	BackgroundColor  $SECONDARY
  #|	BorderColor $DARK
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|
  #|skinparam cloud {
  #|	BackgroundColor $LIGHT-black
  #|	BorderColor $LIGHT
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|
  #|skinparam database {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|
  #|skinparam class {
  #|	$primary_scheme()
  #|	HeaderBackgroundColor $PRIMARY_LIGHT
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $LIGHT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|
  #|skinparam rectangle {
  #|	$primary_scheme()
  #|	BackgroundColor $SECONDARY_LIGHT
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|
  #|skinparam package {
  #|	BackgroundColor $SECONDARY
  #|  	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|
  #|skinparam folder {
  #|	BackgroundColor $SECONDARY_LIGHT
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|
  #|skinparam frame {
  #|	BackgroundColor $SECONDARY_LIGHT
  #|  	BorderColor $INFO
  #|	FontColor $INFO
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|
  #|skinparam state {
  #|	$primary_scheme()
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|
  #|skinparam card {
  #|	BackgroundColor $INFO
  #|	BorderColor $INFO_DARK
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|
  #|skinparam file {
  #|	BackgroundColor $SECONDARY_DARK
  #|	BorderColor $DARK
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub

///|
// name: hacker
// display_name: Hacker
// description: Theme based off of the Jekyll theme of the same name
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration: https://github.com/pages-themes/hacker
let builtin_theme_14 : String =
  #|
  #|!$THEME = "hacker"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "transparent"
  #|!endif
  #|
  #|skinparam BackgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|
  #|''
  #|'' Colors taken from the _default_colors.scss file for jekyll hacker theme
  #|''
  #|!$PRIMARY = "#b5e853"
  #|!$PRIMARY_LIGHT = "#d3f198"
  #|!$PRIMARY_DARK = "#6d8b32"
  #|!$PRIMARY_TEXT = "#151515"
  #|!$SECONDARY = "#6a9fb5"
  #|!$SECONDARY_LIGHT = "#88b2c4"
  #|!$SECONDARY_DARK = "#557f91"
  #|!$SECONDARY_TEXT = "#fefefe"
  #|!$SUCCESS = "#90a959"
  #|!$SUCCESS_LIGHT = "#a6ba7a"
  #|!$INFO = "#aa759f"
  #|!$INFO_LIGHT = "#bb91b2"
  #|!$INFO_DARK = "#885E7F"
  #|!$WARNING = "#f4bf75"
  #|!$WARNING_LIGHT = "#f6cc91"
  #|!$WARNING_TEXT = "#151515"
  #|!$DANGER = "#ac4142"
  #|!$DANGER_LIGHT = "#bd6768"
  #|!$LIGHT = "#151515"
  #|!$DARK = "#eaeaea"
  #|
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|
  #|!procedure $primary_scheme()
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY_LIGHT
  #|	BackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|!endprocedure
  #|
  #|''
  #|'' Style settings
  #|''
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $ORANGE
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|   Padding 15
  #|   roundcorner 20
  #|   BackgroundColor $PRIMARY-$PRIMARY_DARK
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY
  #|    FontColor $INFO
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $DARK
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|  }
  #|  nwdiagDiagram {
  #|	network {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontColor $PRIMARY_LIGHT
  #|	}
  #|	server {
  #|		$primary_scheme()
  #|	}
  #|	arrow {
  #|		FontColor $PRIMARY_LIGHT
  #|		LineColor $PRIMARY_LIGHT
  #|	}
  #|	group {
  #|		BackGroundColor $LIGHT
  #|		LineColor $LIGHT_DARK
  #|		LineThickness 2.0
  #|		Margin 5
  #|		Padding 5
  #|	}
  #|  }
  #|  participant {
  #|    Margin 5 40
  #|    Padding 15 20
  #|  }
  #|  ganttDiagram {
  #|	task {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		Margin 10 2 2 2
  #|		Padding 6
  #|	}
  #|	note {
  #|		FontColor $INFO_TEXT
  #|		LineColor $INFO_DARK
  #|		BackGroundColor $INFO
  #|	}
  #|	separator {
  #|		LineColor $SECONDARY
  #|		BackGroundColor $SECONDARY-$SECONDARY_DARK
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	milestone {
  #|		FontColor $INFO
  #|		FontSize 16
  #|		FontStyle italic
  #|		BackGroundColor $SECONDARY
  #|		LineColor $SECONDARY_DARK
  #|	}
  #|	timeline {
  #|		BackgroundColor $SECONDARY
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	closed {
  #|		BackgroundColor $WARNING_DARK
  #|		FontColor $WARNING_TEXT
  #|	}
  #|  }
  #|</style>
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName       "Verdana"
  #|skinparam defaultFontSize       12
  #|skinparam dpi                   100
  #|skinparam shadowing             false
  #|skinparam roundcorner           40
  #|skinparam BoxPadding            40
  #|skinparam ArrowColor            $DARK
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_DARK
  #|    CBorderColor $SECONDARY_LIGHT
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontColor	                 $PRIMARY
  #|	BorderColor	                 $PRIMARY
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor              $LIGHT-black
  #|}
  #|
  #|
  #|skinparam legend {
  #|	BackgroundColor $SECONDARY
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $DARK
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $SECONDARY_LIGHT-$SECONDARY
  #|  	DiamondBorderColor $SECONDARY_LIGHT
  #|  	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|
  #|skinparam participant {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|
  #|skinparam sequence {
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $BGCOLOR
  #|	BoxBorderColor $DARK
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $SECONDARY
  #|	LifeLineBorderThickness 2
  #|	LifeLineBackgroundColor $SECONDARY_DARK
  #|	''
  #|	GroupBackgroundColor $LIGHT
  #|	GroupBorderColor $DARK
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO
  #|	GroupHeaderBackgroundColor $BGCOLOR
  #|	''
  #|	DividerBackgroundColor $DARK
  #|    DividerBorderColor $DARK
  #|    DividerBorderThickness 2
  #|    DividerFontColor $LIGHT
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceBorderColor $DARK
  #|	ReferenceFontColor $DARK
  #|	ReferenceHeaderBackgroundColor $LIGHT
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BackgroundColor $LIGHT-black
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|
  #|skinparam control {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|
  #|skinparam entity {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|
  #|skinparam boundary {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|
  #|skinparam agent {
  #|	BackgroundColor $WARNING_LIGHT-$WARNING
  #|	BorderColor $WARNING_LIGHT
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $INFO_LIGHT-$INFO_DARK
  #|	BorderColor $INFO_DARK
  #|	FontColor $WHITE
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|
  #|skinparam artifact {
  #|	BackgroundColor $DARK
  #|	BorderColor white
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|
  #|skinparam component {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|
  #|skinparam interface {
  #|	BackgroundColor  $DANGER_LIGHT-$DANGER
  #|	BorderColor  $DANGER_LIGHT
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|
  #|skinparam storage {
  #|	BackgroundColor $WARNING_LIGHT-$WARNING
  #|  	BorderColor $WARNING_LIGHT
  #|	FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|
  #|skinparam node {
  #|	BackgroundColor  $LIGHT-black
  #|	BorderColor $PRIMARY_LIGHT
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|
  #|skinparam cloud {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $DARK
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|
  #|skinparam database {
  #|	BackgroundColor  $LIGHT-black
  #|	BorderColor $PRIMARY_LIGHT
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|
  #|skinparam class {
  #|	$primary_scheme()
  #|	HeaderBackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $LIGHT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $LIGHT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|
  #|skinparam rectangle {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $PRIMARY
  #|	BorderThickness 2
  #|	FontColor $PRIMARY_DARK
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|
  #|skinparam package {
  #|	BackgroundColor $LIGHT
  #|  	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|
  #|skinparam folder {
  #|	BackgroundColor $LIGHT-black
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|
  #|skinparam frame {
  #|	BackgroundColor $LIGHT-black
  #|  	BorderColor $INFO
  #|	FontColor $INFO
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|
  #|skinparam state {
  #|	$primary_scheme()
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|
  #|skinparam card {
  #|	BackgroundColor $INFO_LIGHT-$INFO
  #|	BorderColor $INFO_LIGHT
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|
  #|skinparam file {
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY
  #|	BorderColor $SECONDARY_LIGHT
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|<style>
  #|mindmapDiagram, wbsDiagram {
  #|    element {
  #|	    $primary_scheme()
  #|	}
  #|	:depth(0) {
  #|        fontSize 16
  #|        fontStyle bold
  #|        fontColor $SECONDARY
  #|    }
  #|    :depth(1) {
  #|        fontSize 14
  #|        padding 5
  #|        fontStyle bold
  #|    }
  #|    :depth(2) {
  #|        fontSize 12
  #|        padding 4
  #|    }
  #|    :depth(3) {
  #|        fontSize 11
  #|        padding 3
  #|        fontColor $INFO
  #|    }
  #|
  #|}
  #|</style>
  #|
  #|

///|
// name: lightgray
// display_name: Lightgray
// description: Lightgray theme - mostly grays
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration:
let builtin_theme_15 : String =
  #|
  #|!$THEME = "lightgray"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "transparent"
  #|!endif
  #|
  #|skinparam backgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|
  #|!$WHITE = "#FFF"
  #|!$GRAY_DARK = "#4d4d4d"
  #|!$GRAY = "#737373"
  #|!$LIGHT = "#fcfcfc"
  #|!$DARK = "#303030"
  #|
  #|'' *_LIGHT = tint (lighter) of the main color of 80%
  #|''          where TINT is calculated by clr + (255-clr) * tint_factor
  #|'' *_DARK = shade (darker) of the main color of 80%
  #|''          and SHADE is calculated by clr * (1 - shade_factor)
  #|''
  #|!$FGCOLOR = $DARK
  #|!$PRIMARY = "#e2e2e2"
  #|!$PRIMARY_LIGHT = "#f3f3f3"
  #|!$PRIMARY_DARK = "#888888"
  #|!$PRIMARY_TEXT = "#336699"
  #|!$SECONDARY = "#d2d2d2"
  #|!$SECONDARY_LIGHT = "#dbdbdb"
  #|!$SECONDARY_DARK = "#a8a8a8"
  #|!$SECONDARY_TEXT = "white"
  #|!$INFO = "#336699"
  #|!$INFO_LIGHT = "#5c85ad"
  #|!$INFO_DARK = "#29527a"
  #|!$INFO_TEXT = $WHITE
  #|!$SUCCESS = "#339933"
  #|!$SUCCESS_LIGHT = "#5cad5c"
  #|!$SUCCESS_DARK = "#297a29"
  #|!$SUCCESS_TEXT = $WHITE
  #|!$WARNING = "#ffae42"
  #|!$WARNING_LIGHT = "#ffbe68"
  #|!$WARNING_DARK = "#cc8b35"
  #|!$WARNING_TEXT = $WHITE
  #|!$DANGER = "#ff3333"
  #|!$DANGER_LIGHT = "#ff5c5c"
  #|!$DANGER_DARK = "#cc2929"
  #|!$DANGER_TEXT = $WHITE
  #|
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|
  #|!procedure $primary_scheme()
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY_LIGHT
  #|	BackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|!endprocedure
  #|''
  #|'' Style settings
  #|''
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $ORANGE
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|   Padding 15
  #|   roundcorner 20
  #|   BackgroundColor $PRIMARY-$PRIMARY_DARK
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY
  #|    FontColor $INFO
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $DARK
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|  }
  #|  nwdiagDiagram {
  #|	network {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontColor $PRIMARY_DARK
  #|	}
  #|	server {
  #|		$primary_scheme()
  #|	}
  #|	arrow {
  #|		FontColor $PRIMARY_DARK
  #|		LineColor $PRIMARY_DARK
  #|	}
  #|	group {
  #|		BackGroundColor $LIGHT
  #|		LineColor $LIGHT_DARK
  #|		LineThickness 2.0
  #|		Margin 5
  #|		Padding 5
  #|	}
  #|  }
  #|  participant {
  #|    Margin 5 30
  #|    Padding 15 20
  #|  }
  #|  ganttDiagram {
  #|	task {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		Margin 10 2 2 2
  #|		Padding 6
  #|	}
  #|	note {
  #|		FontColor $INFO_TEXT
  #|		LineColor $INFO_DARK
  #|		BackGroundColor $INFO
  #|	}
  #|	separator {
  #|		LineColor $SECONDARY
  #|		BackGroundColor $SECONDARY-$SECONDARY_DARK
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	milestone {
  #|		FontColor $INFO
  #|		FontSize 16
  #|		FontStyle italic
  #|		BackGroundColor $SECONDARY
  #|		LineColor $SECONDARY_DARK
  #|	}
  #|	timeline {
  #|		BackgroundColor $SECONDARY
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	closed {
  #|		BackgroundColor $WARNING_DARK
  #|		FontColor $WARNING_TEXT
  #|	}
  #|  }
  #|</style>
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName        "Verdana"
  #|skinparam defaultFontSize        12
  #|skinparam dpi                    100
  #|skinparam shadowing              false
  #|skinparam roundcorner            15
  #|skinparam BoxPadding             30
  #|skinparam ArrowColor             $GRAY
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_LIGHT
  #|    CBorderColor $SECONDARY_DARK
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontColor	                 $SECONDARY_TEXT
  #|	BorderColor	                 $SECONDARY
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor              $SECONDARY_LIGHT-$SECONDARY
  #|}
  #|
  #|
  #|skinparam legend {
  #|	BackgroundColor $PRIMARY
  #|	BorderColor $PRIMARY_DARK
  #|	FontColor $PRIMARY_TEXT
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $SECONDARY-$SECONDARY_DARK
  #|  	DiamondBorderColor $SECONDARY_DARK
  #|	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|
  #|skinparam sequence {
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $SECONDARY_TEXT
  #|	BackgroundColor $BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $LIGHT
  #|	BoxBorderColor $GRAY
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $SECONDARY_DARK
  #|	LifeLineBorderThickness 2
  #|	LifeLineBackgroundColor $SECONDARY_LIGHT
  #|	''
  #|	GroupBorderColor $GRAY
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO
  #|	''
  #|	DividerBackgroundColor $WHITE-$LIGHT
  #|    DividerBorderColor $GRAY
  #|    DividerBorderThickness 2
  #|    DividerFontColor $DARK
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceBorderColor $GRAY
  #|	ReferenceFontColor $DARK
  #|	ReferenceHeaderFontColor $INFO
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY_DARK
  #|	BackgroundColor $BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|
  #|skinparam control {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|
  #|skinparam entity {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|
  #|skinparam boundary {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|
  #|skinparam agent {
  #|	BackgroundColor #orange
  #|	BorderColor #999999
  #|	FontColor #333333
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $INFO_LIGHT-$INFO
  #|	BorderColor $INFO
  #|	FontColor $WHITE
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|
  #|skinparam artifact {
  #|	BackgroundColor white-$LIGHT
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $SECONDARY_DARK
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|
  #|skinparam component {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|
  #|skinparam interface {
  #|	BackgroundColor  $DANGER_LIGHT
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|
  #|skinparam storage {
  #|	BackgroundColor $WARNING_LIGHT-$WARNING
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|
  #|skinparam node {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $PRIMARY_LIGHT
  #|	FontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|
  #|skinparam cloud {
  #|	BackgroundColor #F2FCFE-#eeeeee
  #|	BorderColor $F2FCFE
  #|	FontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|
  #|skinparam database {
  #|	$primary_scheme()
  #|	BackgroundColor  $BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|
  #|skinparam class {
  #|	$primary_scheme()
  #|	HeaderBackgroundColor $PRIMARY_LIGHT-$PRIMARY_DARK
  #|	StereotypeFontColor $DARK
  #|	StereotypeFontSize 9
  #|	BorderThickness 1
  #|	AttributeFontColor $DARK
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $LIGHT
  #|	BorderThickness 1
  #|	AttributeFontColor $DARK
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|
  #|skinparam rectangle {
  #|	$primary_scheme()
  #|	BackgroundColor $BGCOLOR
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|
  #|skinparam package {
  #|	$primary_scheme()
  #|	BackgroundColor $BGCOLOR
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|
  #|skinparam folder {
  #|	BackgroundColor $PRIMARY_LIGHT
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|
  #|skinparam frame {
  #|	BackgroundColor $PRIMARY_LIGHT
  #|  	BorderColor $INFO
  #|	FontColor $INFO
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|
  #|skinparam state {
  #|	$primary_scheme()
  #|	BorderColor $PRIMARY_DARK
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|
  #|skinparam card {
  #|	BackgroundColor $INFO_LIGHT-$INFO
  #|	BorderColor $INFO
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|
  #|skinparam file {
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $SECONDARY_TEXT
  #|
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub

///|
// name: mars
// display_name: Mars
// description: The mars theme from future-architect/puml-themes
// author: [future-architect](https://github.com/future-architect)
// release:
// license: Apache License, Version 2.0
// version:
// source: https://github.com/future-architect/puml-themes/tree/master/themes
// inspiration:
let builtin_theme_16 : String =
  #|
  #|skinparam BackgroundColor F9F9F9
  #|skinparam shadowing false
  #|skinparam RoundCorner 7
  #|skinparam ArrowColor 191919
  #|skinparam FontColor 191919
  #|skinparam SequenceLifeLineBorderColor 393939
  #|skinparam SequenceGroupHeaderFontColor 191919
  #|skinparam SequenceGroupFontColor 393939
  #|skinparam SequenceGroupBorderColor 393939
  #|skinparam SequenceGroupBorderThickness 1
  #|
  #|skinparam sequenceDivider {
  #|    BorderColor 191919
  #|    BorderThickness 1
  #|    FontColor 191919
  #|}
  #|
  #|skinparam participant {
  #|    BackgroundColor E55756
  #|    BorderColor 191919
  #|    FontColor F9F9F9
  #|    BorderThickness 1.5
  #|}
  #|
  #|skinparam database {
  #|    BackgroundColor A4DBD8
  #|    BorderColor 191919
  #|    FontColor 191919
  #|}
  #|
  #|skinparam entity {
  #|    BackgroundColor EFBABC
  #|    BorderColor 191919
  #|    FontColor 191919
  #|}
  #|
  #|skinparam note {
  #|    BackgroundColor e5e5e5
  #|    BorderColor 191919
  #|    FontColor 191919
  #|    BorderThickness 1.5
  #|}
  #|
  #|skinparam actor {
  #|    BackgroundColor 191919
  #|    BorderColor 191919
  #|    FontColor 191919
  #|}
  #|
  #|skinparam boundary {
  #|    BackgroundColor EFBABC
  #|    BorderColor 191919
  #|    FontColor 191919
  #|}
  #|
  #|skinparam control {
  #|    BackgroundColor EFBABC
  #|    BorderColor 191919
  #|    FontColor 191919
  #|}
  #|
  #|skinparam collections {
  #|    BackgroundColor E55756
  #|    BorderColor 191919
  #|    FontColor 191919
  #|    BorderThickness 1.5
  #|}
  #|
  #|skinparam queue {
  #|    BackgroundColor E55756
  #|    BorderColor 191919
  #|    FontColor FFF
  #|    BorderThickness 1.5
  #|}

///|
// name: materia-outline
// display_name: Materia Outline
// description: Theme based off of the bootstrap theme of the same name, with outline colors
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration: https://bootswatch.com/materia/
let builtin_theme_17 : String =
  #|
  #|!$THEME = "materia-outline"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "transparent"
  #|!endif
  #|
  #|skinparam backgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|
  #|''
  #|'' Colors taken from the css file of the BS theme
  #|''
  #|!$BLUE = "#2196F3"
  #|!$INDIGO = "#6610f2"
  #|!$PURPLE = "#6f42c1"
  #|!$PINK = "#e83e8c"
  #|!$RED = "#e51c23"
  #|!$ORANGE = "#fd7e14"
  #|!$YELLOW = "#ff9800"
  #|!$GREEN = "#4CAF50"
  #|!$TEAL = "#20c997"
  #|!$CYAN = "#9C27B0"
  #|!$WHITE = "#FFF"
  #|!$GRAY_DARK = "#222"
  #|!$GRAY = "#666"
  #|!$PRIMARY = "#2196F3"
  #|!$SECONDARY = "#fff"
  #|!$SUCCESS = "#4CAF50"
  #|!$INFO = "#9C27B0"
  #|!$WARNING = "#ff9800"
  #|!$DANGER = "#e51c23"
  #|!$LIGHT = "#fff"
  #|!$DARK = "#222"
  #|
  #|'' *_LIGHT = tint (lighter) of the main color of 80%
  #|''          where TINT is calculated by clr + (255-clr) * tint_factor
  #|'' *_DARK = shade (darker) of the main color of 80%
  #|''          and SHADE is calculated by clr * (1 - shade_factor)
  #|''
  #|!$FGCOLOR = $DARK
  #|!$PRIMARY_LIGHT = "#4dabf5"
  #|!$PRIMARY_DARK = "#1a78c2"
  #|!$PRIMARY_TEXT = $PRIMARY
  #|!$SECONDARY_LIGHT = "#fff"
  #|!$SECONDARY_DARK = "#cccccc"
  #|!$SECONDARY_TEXT = $SECONDARY_DARK
  #|!$INFO_LIGHT = "#b052c0"
  #|!$INFO_DARK = "#7D1F8D"
  #|!$INFO_TEXT = $INFO
  #|!$SUCCESS_LIGHT = "#70bf73"
  #|!$SUCCESS_DARK = "#3D8C40"
  #|!$SUCCESS_TEXT = $SUCCESS
  #|!$WARNING_LIGHT = "#ffad33"
  #|!$WARNING_DARK = "#CC7A00"
  #|!$WARNING_TEXT = $WARNING
  #|!$DANGER_LIGHT = "#B7161C"
  #|!$DANGER_TEXT = $DANGER
  #|
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|
  #|!procedure $primary_scheme()
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|!endprocedure
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $ORANGE
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|   Padding 15
  #|   roundcorner 20
  #|   BackgroundColor $BGCOLOR
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY
  #|    FontColor $INFO
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $DARK
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $BGCOLOR
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|  }
  #|  nwdiagDiagram {
  #|	network {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontColor $PRIMARY_DARK
  #|	}
  #|	server {
  #|		$primary_scheme()
  #|	}
  #|	arrow {
  #|		FontColor $PRIMARY_DARK
  #|		LineColor $PRIMARY_DARK
  #|	}
  #|	group {
  #|		BackGroundColor $LIGHT
  #|		LineColor $LIGHT_DARK
  #|		LineThickness 2.0
  #|		Margin 5
  #|		Padding 5
  #|	}
  #|  }
  #|  participant {
  #|    Margin 5 40
  #|    Padding 15 20
  #|  }
  #|  ganttDiagram {
  #|	task {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		Margin 10 2 2 2
  #|		Padding 6
  #|	}
  #|	note {
  #|		FontColor $INFO_TEXT
  #|		LineColor $INFO_DARK
  #|		BackGroundColor $BGCOLOR
  #|	}
  #|	separator {
  #|		LineColor $SECONDARY_DARK
  #|		BackGroundColor $BGCOLOR
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	milestone {
  #|		FontColor $INFO
  #|		FontSize 16
  #|		FontStyle italic
  #|		BackGroundColor $SECONDARY
  #|		LineColor $SECONDARY_DARK
  #|	}
  #|	timeline {
  #|		BackgroundColor $SECONDARY
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	closed {
  #|		BackgroundColor $WARNING_DARK
  #|		FontColor $WARNING_TEXT
  #|	}
  #|  }
  #|</style>
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName       "Verdana"
  #|skinparam defaultFontSize       12
  #|skinparam dpi                   100
  #|skinparam shadowing             true
  #|skinparam roundcorner           8
  #|skinparam BoxPadding            40
  #|skinparam TitleFontColor	    $DARK
  #|skinparam TitleFontSize	    	20
  #|skinparam TitleBorderThickness 	0
  #|skinparam ArrowColor            $GRAY
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_LIGHT
  #|    CBorderColor $SECONDARY_DARK
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontColor	                 $PRIMARY
  #|	BorderColor	                 $SECONDARY_DARK
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor              $BGCOLOR
  #|}
  #|
  #|skinparam legend {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $DARK
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|
  #|skinparam activity {
  #|	$primary_scheme()
  #|	' FontColor $PRIMARY_TEXT
  #|	' BorderColor $PRIMARY
  #|	' BackgroundColor $BGCOLOR
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $BGCOLOR
  #|  	DiamondBorderColor $SECONDARY_DARK
  #|	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	$primary_scheme()
  #|	' FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|
  #|skinparam sequence {
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $BGCOLOR
  #|	BoxBorderColor $GRAY
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $SECONDARY_DARK
  #|	LifeLineBorderThickness 2
  #|	LifeLineBackgroundColor $BGCOLOR
  #|	''
  #|	GroupBorderColor $GRAY
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO
  #|	''
  #|	DividerBackgroundColor $BGCOLOR
  #|    DividerBorderColor $GRAY
  #|    DividerBorderThickness 2
  #|    DividerFontColor $DARK
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceBorderColor $GRAY
  #|	ReferenceFontColor $DARK
  #|	ReferenceHeaderFontColor $INFO
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|
  #|skinparam collections {
  #|	$primary_scheme()
  #|	' BackgroundColor $BGCOLOR
  #|	' BorderColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|
  #|skinparam control {
  #|	$primary_scheme()
  #|	' BackgroundColor  $BGCOLOR
  #|	' BorderColor $PRIMARY_DARK
  #|	' FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|
  #|skinparam entity {
  #|	$primary_scheme()
  #|	' BackgroundColor  $BGCOLOR
  #|	' BorderColor $PRIMARY_DARK
  #|	' FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|
  #|skinparam boundary {
  #|	$primary_scheme()
  #|	' BackgroundColor  $BGCOLOR
  #|	' BorderColor $PRIMARY_DARK
  #|	' FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|
  #|skinparam agent {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor #999999
  #|	FontColor #333333
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $INFO
  #|	FontColor $INFO
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|
  #|skinparam artifact {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $GRAY
  #|	FontColor $GRAY
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|
  #|skinparam component {
  #|	$primary_scheme()
  #|	' BackgroundColor  $BGCOLOR
  #|	' BorderColor  $SUCCESS
  #|	' FontColor $SUCCESS_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|
  #|skinparam interface {
  #|	BackgroundColor  $BGCOLOR
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|
  #|skinparam storage {
  #|	BackgroundColor $BGCOLOR
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|
  #|skinparam node {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $DARK
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|
  #|skinparam cloud {
  #|	BackgroundColor #F2FCFE-#eeeeee
  #|	BorderColor #F2FCFE
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|
  #|skinparam database {
  #|	$primary_scheme()
  #|	' BackgroundColor  $BGCOLOR
  #|	' BorderColor $PRIMARY_DARK
  #|	' FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|
  #|skinparam class {
  #|	$primary_scheme()
  #|	FontColor $LIGHT
  #|	HeaderBackgroundColor $PRIMARY-$PRIMARY_DARK
  #|	' FontColor $PRIMARY_TEXT
  #|	' BackgroundColor $BGCOLOR
  #|	' BorderColor $PRIMARY_DARK
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $DARK
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|
  #|skinparam object {
  #|	$primary_scheme()
  #|	' FontColor $SUCCESS
  #|	' BackgroundColor $BGCOLOR
  #|	' BorderColor $SECONDARY_DARK
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $SECONDARY_DARK
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	' BackgroundColor $BGCOLOR
  #|	' BorderColor $SECONDARY_DARK
  #|	BorderThickness 2
  #|	' FontColor $SECONDARY_TEXT
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|
  #|skinparam rectangle {
  #|	$primary_scheme()
  #|	' BackgroundColor $BGCOLOR
  #|	' BorderColor $PRIMARY_DARK
  #|	BorderThickness 2
  #|	' FontColor $PRIMARY
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|
  #|skinparam package {
  #|	BackgroundColor $BGCOLOR
  #|  	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|
  #|skinparam folder {
  #|	BackgroundColor $BGCOLOR
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|
  #|skinparam frame {
  #|	BackgroundColor $BGCOLOR
  #|  	BorderColor $INFO
  #|	FontColor $INFO
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|
  #|skinparam state {
  #|	$primary_scheme()
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	' BackgroundColor $BGCOLOR
  #|	' BorderColor $SECONDARY_DARK
  #|	' FontColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|
  #|skinparam queue {
  #|	$primary_scheme()
  #|	' BackgroundColor $BGCOLOR
  #|  	' BorderColor $WARNING_DARK
  #|	' FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|
  #|skinparam card {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $INFO
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|
  #|skinparam file {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $GRAY
  #|	FontColor $GRAY
  #|
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|
  #|skinparam stack {
  #|	$primary_scheme()
  #|	' BackgroundColor $BGCOLOR
  #|	' BorderColor $PRIMARY
  #|	' FontColor $PRIMARY_TEXT
  #|}
  #|!endsub

///|
// name: materia
// display_name: Materia
// description: Theme based off of the bootstrap theme of the same name
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration: https://bootswatch.com/materia/
let builtin_theme_18 : String =
  #|
  #|!$THEME = "materia"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "transparent"
  #|!endif
  #|
  #|skinparam backgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|
  #|''
  #|'' Colors taken from the css file of the BS theme
  #|''
  #|!$BLUE = "#2196F3"
  #|!$INDIGO = "#6610f2"
  #|!$PURPLE = "#6f42c1"
  #|!$PINK = "#e83e8c"
  #|!$RED = "#e51c23"
  #|!$ORANGE = "#fd7e14"
  #|!$YELLOW = "#ff9800"
  #|!$GREEN = "#4CAF50"
  #|!$TEAL = "#20c997"
  #|!$CYAN = "#9C27B0"
  #|!$WHITE = "#FFF"
  #|!$GRAY_DARK = "#222"
  #|!$GRAY = "#666"
  #|!$PRIMARY = "#2196F3"
  #|!$SECONDARY = "#fff"
  #|!$SUCCESS = "#4CAF50"
  #|!$INFO = "#9C27B0"
  #|!$WARNING = "#ff9800"
  #|!$DANGER = "#e51c23"
  #|!$LIGHT = "#fff"
  #|!$DARK = "#222"
  #|
  #|'' *_LIGHT = tint (lighter) of the main color of 80%
  #|'' *_DARK = shade (darker) of the main color of 80%
  #|''
  #|!$FGCOLOR = $DARK
  #|!$PRIMARY_LIGHT = "#4dabf5"
  #|!$PRIMARY_DARK = "#1a78c2"
  #|!$PRIMARY_TEXT = $WHITE
  #|!$SECONDARY_LIGHT = "#fff"
  #|!$SECONDARY_DARK = "#cccccc"
  #|!$SECONDARY_TEXT = $DARK
  #|!$INFO_LIGHT = "#b052c0"
  #|!$INFO_DARK = "#7D1F8D"
  #|!$INFO_TEXT = $WHITE
  #|!$SUCCESS_LIGHT = "#70bf73"
  #|!$SUCCESS_DARK = "#3D8C40"
  #|!$SUCCESS_TEXT = $WHITE
  #|!$WARNING_LIGHT = "#ffad33"
  #|!$WARNING_DARK = "#CC7A00"
  #|!$WARNING_TEXT = $WHITE
  #|!$DANGER_DARK = "#b7161c"
  #|!$DANGER_LIGHT = "#B7161C"
  #|!$DANGER_TEXT = $WHITE
  #|
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|
  #|!procedure $primary_scheme()
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY
  #|	BackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|!endprocedure
  #|''
  #|'' Style settings
  #|''
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $ORANGE
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|   Padding 15
  #|   roundcorner 20
  #|   BackgroundColor $PRIMARY-$PRIMARY_DARK
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY
  #|    FontColor $INFO
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $DARK
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|  }
  #|  nwdiagDiagram {
  #|	network {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontColor $PRIMARY_DARK
  #|	}
  #|	server {
  #|		$primary_scheme()
  #|	}
  #|	arrow {
  #|		FontColor $PRIMARY_DARK
  #|		LineColor $PRIMARY_DARK
  #|	}
  #|	group {
  #|		BackGroundColor $LIGHT
  #|		LineColor $LIGHT_DARK
  #|		LineThickness 2.0
  #|		Margin 5
  #|		Padding 5
  #|	}
  #|  }
  #|  participant {
  #|    Margin 5 40
  #|    Padding 15 20
  #|  }
  #|  ganttDiagram {
  #|	task {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		Margin 10 2 2 2
  #|		Padding 6
  #|	}
  #|	note {
  #|		FontColor $INFO_TEXT
  #|		LineColor $INFO_DARK
  #|		BackGroundColor $INFO
  #|	}
  #|	separator {
  #|		LineColor $SECONDARY
  #|		BackGroundColor $SECONDARY-$SECONDARY_DARK
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	milestone {
  #|		FontColor $INFO
  #|		FontSize 16
  #|		FontStyle italic
  #|		BackGroundColor $SECONDARY
  #|		LineColor $SECONDARY_DARK
  #|	}
  #|	timeline {
  #|		BackgroundColor $SECONDARY
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	closed {
  #|		BackgroundColor $WARNING_DARK
  #|		FontColor $WARNING_TEXT
  #|	}
  #|  }
  #|</style>
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName       "Verdana"
  #|skinparam defaultFontSize       12
  #|skinparam dpi                   100
  #|skinparam shadowing             true
  #|skinparam roundcorner           8
  #|skinparam BoxPadding            40
  #|skinparam ArrowColor            $GRAY
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_LIGHT
  #|    CBorderColor $SECONDARY_DARK
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontColor	                 $PRIMARY
  #|	BorderColor	                 $SECONDARY_DARK
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor              $SECONDARY_LIGHT-$SECONDARY
  #|}
  #|
  #|skinparam legend {
  #|	BackgroundColor $SECONDARY
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $DARK
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $WHITE-$SECONDARY_LIGHT
  #|  	DiamondBorderColor $SECONDARY_DARK
  #|	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|
  #|skinparam sequence {
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $PRIMARY
  #|	BackgroundColor transparent
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $LIGHT
  #|	BoxBorderColor $GRAY
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $SECONDARY_DARK
  #|	LifeLineBorderThickness 2
  #|	LifeLineBackgroundColor $SECONDARY_LIGHT
  #|	''
  #|	GroupBorderColor $GRAY
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO
  #|	''
  #|	DividerBackgroundColor $WHITE-$LIGHT
  #|    DividerBorderColor $GRAY
  #|    DividerBorderThickness 2
  #|    DividerFontColor $DARK
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceBorderColor $GRAY
  #|	ReferenceFontColor $DARK
  #|	ReferenceHeaderFontColor $INFO
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BackgroundColor transparent
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|
  #|skinparam control {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|
  #|skinparam entity {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|
  #|skinparam boundary {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|
  #|skinparam agent {
  #|	BackgroundColor #orange
  #|	BorderColor #999999
  #|	FontColor #333333
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $INFO_LIGHT-$INFO
  #|	BorderColor $INFO
  #|	FontColor $WHITE
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|
  #|skinparam artifact {
  #|	BackgroundColor $WHITE-$LIGHT
  #|	BorderColor $GRAY
  #|	FontColor $GRAY
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|
  #|skinparam component {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|
  #|skinparam interface {
  #|	BackgroundColor  $DANGER_LIGHT
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|
  #|skinparam storage {
  #|	BackgroundColor $WARNING_LIGHT-$WARNING
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|
  #|skinparam node {
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY
  #|	BorderColor $DARK
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|
  #|skinparam cloud {
  #|	BackgroundColor #F2FCFE-#eeeeee
  #|	BorderColor #F2FCFE
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|
  #|skinparam database {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|
  #|skinparam class {
  #|	$primary_scheme()
  #|	HeaderBackgroundColor $PRIMARY-$PRIMARY_DARK
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $LIGHT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|
  #|skinparam rectangle {
  #|	FontColor $PRIMARY
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|
  #|skinparam package {
  #|	$primary_scheme()
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|
  #|skinparam folder {
  #|	BackgroundColor $WHITE-$SECONDARY_LIGHT
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|
  #|skinparam frame {
  #|	BackgroundColor $WHITE-$SECONDARY_LIGHT
  #|  	BorderColor $INFO
  #|	FontColor $INFO
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|
  #|skinparam state {
  #|	$primary_scheme()
  #|	BorderColor $PRIMARY_DARK
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|
  #|skinparam card {
  #|	BackgroundColor $INFO_LIGHT-$INFO
  #|	BorderColor $INFO
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|
  #|skinparam file {
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY
  #|	BorderColor $GRAY
  #|	FontColor $GRAY
  #|
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub

///|
// name: metal
// display_name: Metal
// description: Mostly metal grays theme
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration:
let builtin_theme_19 : String =
  #|
  #|!$THEME = "metal"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "transparent"
  #|!endif
  #|
  #|skinparam backgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|
  #|!$WHITE = "#fdfdfd"
  #|!$GRAY_DARK = "#4d4d4d"
  #|!$GRAY = "#737373"
  #|!$LIGHT = "#f2f2f2"
  #|!$DARK = "#4d4d4d"
  #|
  #|!$SILVER = "#c0c0c0"
  #|!$COPPER = "#B87333c"
  #|!$STEELBLUE = "#4682b4"
  #|!$LIGHTSTEELBLUE = "#B0C4DE"
  #|!$LIGHTSTEELBLUE_DARK = "#8d9db2"
  #|!$LIGHTSTEELBLUE_LIGHT = "#c0d0e5"
  #|!$ALUMINUM = "#c9ced0"
  #|!$ALUMINUM_DARK = "#a1a5a6"
  #|!$ALUMINUM_LIGHT = "#d4d8d9"
  #|!$BRONZE = "#CD7F32"
  #|!$BRONZE_DARK = "#a46628"
  #|!$BRONZE_LIGHT = "#d7995b"
  #|!$GOLD = "#FFD700"
  #|!$PLATINUM = "#E5E4E2"
  #|!$RUST = "#B7410E"
  #|
  #|
  #|
  #|'' *_LIGHT = tint (lighter) of the main color of 80%
  #|''          where TINT is calculated by clr + (255-clr) * tint_factor
  #|'' *_DARK = shade (darker) of the main color of 80%
  #|''          and SHADE is calculated by clr * (1 - shade_factor)
  #|''
  #|!$FGCOLOR = $DARK
  #|!$PRIMARY = $PLATINUM
  #|!$PRIMARY_LIGHT = "#eae9e8"
  #|!$PRIMARY_DARK = "#b7b6b5"
  #|!$PRIMARY_TEXT = $STEELBLUE
  #|!$SECONDARY = $SILVER
  #|!$SECONDARY_LIGHT = "#cdcdcd"
  #|!$SECONDARY_DARK = "#9a9a9a"
  #|!$SECONDARY_TEXT = $WHITE
  #|!$INFO = $STEELBLUE
  #|!$INFO_LIGHT = "#5c85ad"
  #|!$INFO_DARK = "#29527a"
  #|!$INFO_TEXT = $WHITE
  #|!$SUCCESS = "#339933"
  #|!$SUCCESS_LIGHT = "#5cad5c"
  #|!$SUCCESS_DARK = "#297a29"
  #|!$SUCCESS_TEXT = $WHITE
  #|!$WARNING = $GOLD
  #|!$WARNING_LIGHT = "#ffdf33"
  #|!$WARNING_DARK = "#ccac00"
  #|!$WARNING_TEXT = $WHITE
  #|!$DANGER = $RUST
  #|!$DANGER_LIGHT = "#c5673e"
  #|!$DANGER_DARK = "#92340b"
  #|!$DANGER_TEXT = $WHITE
  #|
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|
  #|!procedure $primary_scheme()
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY_DARK
  #|	BackgroundColor $PRIMARY-$PRIMARY_DARK
  #|!endprocedure
  #|''
  #|'' Style settings
  #|''
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $ORANGE
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|   Padding 15
  #|   roundcorner 20
  #|   BackgroundColor $PRIMARY-$PRIMARY_DARK
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY
  #|    FontColor $INFO
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $DARK
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|  }
  #|  nwdiagDiagram {
  #|	network {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontColor $PRIMARY_DARK
  #|	}
  #|	server {
  #|		$primary_scheme()
  #|	}
  #|	arrow {
  #|		FontColor $PRIMARY_DARK
  #|		LineColor $PRIMARY_DARK
  #|	}
  #|	group {
  #|		BackGroundColor $LIGHT
  #|		LineColor $LIGHT_DARK
  #|		LineThickness 2.0
  #|		Margin 5
  #|		Padding 5
  #|	}
  #|  }
  #|  participant {
  #|    Margin 5 30
  #|    Padding 15 20
  #|  }
  #|  ganttDiagram {
  #|	task {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		Margin 10 2 2 2
  #|		Padding 6
  #|	}
  #|	note {
  #|		FontColor $INFO_TEXT
  #|		LineColor $INFO_DARK
  #|		BackGroundColor $INFO
  #|	}
  #|	separator {
  #|		LineColor $SECONDARY
  #|		BackGroundColor $SECONDARY-$SECONDARY_DARK
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	milestone {
  #|		FontColor $INFO
  #|		FontSize 16
  #|		FontStyle italic
  #|		BackGroundColor $SECONDARY
  #|		LineColor $SECONDARY_DARK
  #|	}
  #|	timeline {
  #|		BackgroundColor $SECONDARY
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	closed {
  #|		BackgroundColor $WARNING_DARK
  #|		FontColor $WARNING_TEXT
  #|	}
  #|  }
  #|</style>
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName        "Verdana"
  #|skinparam defaultFontSize        12
  #|skinparam dpi                    100
  #|skinparam shadowing              false
  #|skinparam roundcorner            15
  #|skinparam BoxPadding             30
  #|skinparam ArrowColor             $GRAY
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_LIGHT
  #|    CBorderColor $SECONDARY_DARK
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontColor	                 $WHITE
  #|	BorderColor	                 $SECONDARY_DARK
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor              $SECONDARY_LIGHT-$SECONDARY_DARK
  #|}
  #|
  #|
  #|skinparam legend {
  #|	BackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $PRIMARY_TEXT
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $BRONZE
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $SECONDARY-$SECONDARY_DARK
  #|  	DiamondBorderColor $SECONDARY_DARK
  #|	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|
  #|skinparam sequence {
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $WHITE
  #|	BackgroundColor $BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $LIGHT
  #|	BoxBorderColor $GRAY
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $SECONDARY_DARK
  #|	LifeLineBorderThickness 3
  #|	LifeLineBackgroundColor $SECONDARY_LIGHT-$SECONDARY_DARK
  #|	''
  #|	GroupBorderColor $GRAY
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO
  #|	''
  #|	DividerBackgroundColor $WHITE-$LIGHT
  #|    DividerBorderColor $GRAY
  #|    DividerBorderThickness 2
  #|    DividerFontColor $DARK
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceBorderColor $GRAY
  #|	ReferenceFontColor $DARK
  #|	ReferenceHeaderFontColor $INFO
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY_DARK
  #|	BackgroundColor $BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|
  #|skinparam control {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|
  #|skinparam entity {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|
  #|skinparam boundary {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|
  #|skinparam agent {
  #|	BackgroundColor #orange
  #|	BorderColor #999999
  #|	FontColor #333333
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $LIGHTSTEELBLUE_LIGHT-$LIGHTSTEELBLUE_DARK
  #|	BorderColor $LIGHTSTEELBLUE_DARK
  #|	FontColor $WHITE
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|
  #|skinparam artifact {
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY_DARK
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|
  #|skinparam component {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|
  #|skinparam interface {
  #|	BackgroundColor  $DANGER_LIGHT
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|
  #|skinparam storage {
  #|	BackgroundColor $WARNING_LIGHT-$WARNING_DARK
  #|  	BorderColor $WARNING_DARK
  #|	FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|
  #|skinparam node {
  #|	BackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|	BorderColor $PRIMARY
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|
  #|skinparam cloud {
  #|	BackgroundColor #F2FCFE-#eeeeee
  #|	BorderColor #F2FCFE
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|
  #|skinparam database {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|
  #|skinparam class {
  #|	$primary_scheme()
  #|	HeaderBackgroundColor $PRIMARY_LIGHT-$PRIMARY_DARK
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $DARK
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $LIGHT
  #|	BorderThickness 1
  #|	AttributeFontColor $WHITE
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|
  #|skinparam rectangle {
  #|	$primary_scheme()
  #|	BackgroundColor $WHITE-$LIGHT
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|
  #|skinparam package {
  #|	$primary_scheme()
  #|	BackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|
  #|skinparam folder {
  #|	BackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|  	BorderColor $RUST
  #|	FontColor $RUST
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|
  #|skinparam frame {
  #|	BackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|  	BorderColor $INFO
  #|	FontColor $INFO
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|
  #|skinparam state {
  #|	$primary_scheme()
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY
  #|    AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|
  #|skinparam card {
  #|	BackgroundColor $INFO_LIGHT-$INFO_DARK
  #|	BorderColor $INFO
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|
  #|skinparam file {
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY_DARK
  #|	BorderColor $GRAY
  #|	FontColor $LIGHT
  #|
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub

///|
// name: mimeograph
// display_name: Mimeograph
// description: A purple on grey theme based on the Mimeograph reproduction process
// author: Matthew Leather
// release:
// license:
// version:
// source:
// inspiration: https://en.wikipedia.org/wiki/Mimeograph
let builtin_theme_20 : String =
  #|
  #|!$THEME = "mimeograph"
  #|
  #|!$BGCOLOR = "#D9D3D0"
  #|!$FGCOLOR = "#9275B6"
  #|
  #|!ifndef $FONT_NAME
  #|  !$FONT_NAME = "Verdana"
  #|!endif
  #|
  #|!ifndef $FONT_NAME_MONOSPACED
  #|  !$FONT_NAME_MONOSPACED = "Courier"
  #|!endif
  #|
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $FGCOLOR
  #|    FontName $FONT_NAME
  #|    HyperLinkColor $FGCOLOR
  #|    LineColor $FGCOLOR
  #|    LineThickness 1
  #|    Margin 5
  #|  }
  #|  document {
  #|    caption {
  #|      LineThickness 0
  #|    }
  #|    footer {
  #|      LineThickness 0
  #|    }
  #|    header {
  #|      LineThickness 0
  #|    }
  #|    title {
  #|      FontSize 22
  #|      LineThickness 0
  #|    }
  #|  }
  #|  node {
  #|    MaximumWidth 300
  #|  }
  #|  participant {
  #|    Margin 5 10
  #|    Padding 5 5
  #|  }
  #|</style>
  #|
  #|skinparam ArrowLollipopColor $FGCOLOR
  #|skinparam BackgroundColor $BGCOLOR
  #|skinparam DefaultFontName $FONT_NAME
  #|skinparam DefaultMonospacedFontName $FONT_NAME_MONOSPACED
  #|skinparam LifelineStrategy nosolid
  #|skinparam SequenceLifeLineBorderColor $FGCOLOR
  #|skinparam Shadowing false
  #|skinparam UseBetaStyle true
  #|
  #|skinparam Activity {
  #|  BackgroundColor $BGCOLOR
  #|  BarColor $FGCOLOR
  #|  BorderColor $FGCOLOR
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Boundary {
  #|  FontColor $FGCOLOR
  #|}
  #|skinparam Box {
  #|  Padding 5
  #|}
  #|skinparam CircledCharacter {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME_MONOSPACED
  #|  Radius 9
  #|}
  #|skinparam Class {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam ClassAttribute {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam ClassStereotype {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Footer {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Header {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Hyperlink {
  #|  Color $FGCOLOR
  #|}
  #|skinparam IconPackage {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam IconPrivate {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam IconProtected {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam IconPublic {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam Note {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Object {
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam Package {
  #|  BorderColor $FGCOLOR
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam State {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeA {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeC {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeE {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeI {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeN {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam UseCaseStereoType {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}

///|
// name: minty
// display_name: Minty
// description: Theme based off of the bootstrap theme of the same name
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration: https://bootswatch.com/minty/
let builtin_theme_21 : String =
  #|
  #|!$THEME = "minty"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "transparent"
  #|!endif
  #|
  #|skinparam backgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|
  #|''
  #|'' Colors taken from the css file of the BS theme
  #|''
  #|!$BLUE = "#007bff"
  #|!$INDIGO = "#6610f2"
  #|!$PURPLE = "#6f42c1"
  #|!$PINK = "#e83e8c"
  #|!$RED = "#ff7851"
  #|!$ORANGE = "#fd7e14"
  #|!$YELLOW = "#ffce67"
  #|!$GREEN = "#56cc9d"
  #|!$TEAL = "#20c997"
  #|!$CYAN = "#6cc3d5"
  #|!$WHITE = "#fff"
  #|!$GRAY = "#888"
  #|!$GRAYDARK = "#343a40"
  #|!$PRIMARY = "#78c2ad"
  #|!$SECONDARY = "#f3969a"
  #|!$SUCCESS = "#56cc9d"
  #|!$INFO = "#6cc3d5"
  #|!$WARNING = "#ffce67"
  #|!$DANGER = "#ff7851"
  #|!$LIGHT = "#f8f9fa"
  #|!$DARK = "#343a40"
  #|
  #|'' *_DARK = tint (lighter) of the main color of 80%
  #|''          where TINT is calculated by clr + (255-clr) * tint_factor
  #|'' *_LIGHT = shade (darker) of the main color of 80%
  #|''          and SHADE is calculated by clr * (1 - shade_factor)
  #|''
  #|!$FGCOLOR = $WHITE
  #|!$PRIMARY_DARK = "#6caf9c"
  #|!$PRIMARY_LIGHT = "#86c8b5"
  #|!$PRIMARY_TEXT = $WHITE
  #|!$SECONDARY_DARK = "#db878b"
  #|!$SECONDARY_LIGHT = "#f4a1a4"
  #|!$SECONDARY_TEXT = $WHITE
  #|!$INFO_DARK = "#61b0c0"
  #|!$INFO_LIGHT = "#7bc9d9"
  #|!$INFO_TEXT = $WHITE
  #|!$SUCCESS_DARK = "#4db88d"
  #|!$SUCCESS_LIGHT = "#67d1a7"
  #|!$SUCCESS_TEXT = $WHITE
  #|!$WARNING_DARK = "#e6b95d"
  #|!$WARNING_LIGHT = "#ffd376"
  #|!$WARNING_TEXT = $WHITE
  #|!$DANGER_DARK = "#e66c49"
  #|!$DANGER_LIGHT = "#ff8662"
  #|!$DANGER_TEXT = $WHITE
  #|!$DARK_DARK = "#2f343a"
  #|!$DARK_LIGHT = "#484e53"
  #|!$LIGHT_DARK = "#dfe0e1"
  #|!$LIGHT_LIGHT = "#f9fafb"
  #|
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|
  #|!procedure $primary_scheme()
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY
  #|	BackgroundColor $PRIMARY_LIGHT
  #|!endprocedure
  #|''
  #|'' Style settings
  #|''
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $ORANGE
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|   Padding 15
  #|   roundcorner 20
  #|   BackgroundColor $PRIMARY-$PRIMARY_DARK
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY
  #|    FontColor $INFO
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $DARK
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|  }
  #|  nwdiagDiagram {
  #|	network {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontColor $PRIMARY_DARK
  #|	}
  #|	server {
  #|		$primary_scheme()
  #|	}
  #|	arrow {
  #|		FontColor $PRIMARY_DARK
  #|		LineColor $PRIMARY_DARK
  #|	}
  #|	group {
  #|		BackGroundColor $LIGHT
  #|		LineColor $LIGHT_DARK
  #|		LineThickness 2.0
  #|		Margin 5
  #|		Padding 5
  #|	}
  #|  }
  #|  participant {
  #|    Margin 5 40
  #|    Padding 15 20
  #|  }
  #|  ganttDiagram {
  #|	task {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		Margin 10 2 2 2
  #|		Padding 6
  #|	}
  #|	note {
  #|		FontColor $INFO_TEXT
  #|		LineColor $INFO_DARK
  #|		BackGroundColor $INFO
  #|	}
  #|	separator {
  #|		LineColor $SECONDARY
  #|		BackGroundColor $SECONDARY-$SECONDARY_DARK
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	milestone {
  #|		FontColor $INFO
  #|		FontSize 16
  #|		FontStyle italic
  #|		BackGroundColor $SECONDARY
  #|		LineColor $SECONDARY_DARK
  #|	}
  #|	timeline {
  #|		BackgroundColor $SECONDARY
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	closed {
  #|		BackgroundColor $WARNING_DARK
  #|		FontColor $WARNING_TEXT
  #|	}
  #|  }
  #|</style>
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName       "Verdana"
  #|skinparam defaultFontSize       12
  #|skinparam dpi                   100
  #|skinparam shadowing             false
  #|skinparam roundcorner           8
  #|skinparam BoxPadding            40
  #|skinparam ArrowColor            $DARK
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_LIGHT
  #|    CBorderColor $SECONDARY_DARK
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontColor	                 $PRIMARY_DARK
  #|	BorderColor	                 $SECONDARY_DARK
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor              $SECONDARY_LIGHT-$SECONDARY
  #|}
  #|
  #|skinparam legend {
  #|	BackgroundColor $SECONDARY
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $LIGHT
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $SECONDARY_LIGHT
  #|  	DiamondBorderColor $SECONDARY_DARK
  #|  	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|
  #|skinparam sequence {
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $BGCOLOR
  #|	BoxBorderColor $DARK
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $SECONDARY
  #|	LifeLineBorderThickness 2
  #|	LifeLineBackgroundColor $SECONDARY_DARK
  #|	''
  #|	GroupBorderColor $DARK
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO
  #|	GroupBackgroundColor $SECONDARY
  #|	GroupHeaderBackgroundColor $BGCOLOR
  #|	''
  #|	DividerBackgroundColor $DARK
  #|    DividerBorderColor $DARK
  #|    DividerBorderThickness 2
  #|    DividerFontColor $LIGHT
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceBorderColor $DARK
  #|	ReferenceFontColor $DARK
  #|	ReferenceHeaderFontColor $INFO
  #|	ReferenceHeaderBackgroundColor $SECONDARY
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|
  #|skinparam control {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|
  #|skinparam entity {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|
  #|skinparam boundary {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|
  #|skinparam agent {
  #|	BackgroundColor $WARNING
  #|	BorderColor $WARNING_LIGHT
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $INFO
  #|	BorderColor $INFO_DARK
  #|	FontColor $WHITE
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|
  #|skinparam artifact {
  #|	BackgroundColor $DARK
  #|	BorderColor $DARK_DARK
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|
  #|skinparam component {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|
  #|skinparam interface {
  #|	BackgroundColor  $DANGER_DARK
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|
  #|skinparam storage {
  #|	BackgroundColor $WARNING
  #|  	BorderColor $WARNING_DARK
  #|	FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|
  #|skinparam node {
  #|	BackgroundColor  $SECONDARY
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|
  #|skinparam cloud {
  #|	BackgroundColor #F2FCFE-#eeeeee
  #|	BorderColor #F2FCFE
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|
  #|skinparam database {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|
  #|skinparam class {
  #|	$primary_scheme()
  #|	HeaderBackgroundColor $PRIMARY_LIGHT
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $DARK
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|
  #|skinparam rectangle {
  #|	$primary_scheme()
  #|	BackgroundColor $SECONDARY_LIGHT
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|
  #|skinparam package {
  #|	BackgroundColor $SECONDARY
  #|  	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|
  #|skinparam folder {
  #|	BackgroundColor $SECONDARY_LIGHT
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|
  #|skinparam frame {
  #|	BackgroundColor $SECONDARY_LIGHT
  #|  	BorderColor $INFO
  #|	FontColor $INFO
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|
  #|skinparam state {
  #|	$primary_scheme()
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|
  #|skinparam card {
  #|	BackgroundColor $INFO
  #|	BorderColor $INFO_DARK
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|
  #|skinparam file {
  #|	BackgroundColor $SECONDARY_DARK
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub

///|
// name: mono
// display_name: Mono
// description: A mostly monochrome theme with monospaced font, that adds more structure and tidiness with better shapes control, brought by monospaced font
// author: Denis Bondarenko feat Matthew Leather
// release:
// license:
// version:
// source:
// inspiration:
let builtin_theme_22 : String =
  #|
  #|!$THEME = "mono"
  #|
  #|' Theme colors
  #|
  #|!if %not(%variable_exists("$CLR_BG"))
  #|  !$CLR_BG = "white"
  #|!endif
  #|
  #|' For icons bg in legend. usage: <THM_BG>
  #|!ifndef THM_BG
  #|  !define THM_BG #$CLR_BG
  #|!endif
  #|
  #|' Highlighted background
  #|!if %not(%variable_exists("$CLR_BG_EMPH"))
  #|  !$CLR_BG_EMPH = "#eee"
  #|!endif
  #|
  #|' Main foreground color
  #|!if %not(%variable_exists("$CLR_FG"))
  #|  !$CLR_FG = "black"
  #|!endif
  #|
  #|' Less hued, 3 levels
  #|
  #|!if %not(%variable_exists("$CLR_FG_DIMMED"))
  #|  !$CLR_FG_DIMMED = "#666"
  #|!endif
  #|
  #|!if %not(%variable_exists("$CLR_FG_DIMMED_2"))
  #|  !$CLR_FG_DIMMED_2 = "#999"
  #|!endif
  #|
  #|!if %not(%variable_exists("$CLR_FG_DIMMED_3"))
  #|  !$CLR_FG_DIMMED_3 = "#ccc"
  #|!endif
  #|
  #|' Hyperlinks color
  #|!if %not(%variable_exists("$CLR_HYPERLINK"))
  #|  !$CLR_HYPERLINK = "#333"
  #|!endif
  #|
  #|' Theme fonts
  #|
  #|' Basic font
  #|!ifndef $FNT
  #|
  #|' Multiple fallback fonts defined
  #|  !$FNT_MONO = "Courier"
  #|  !$FNT_MONO = "Courier New"
  #|  !$FNT = "DejaVu Sans Mono"
  #|  !$FNT = "monospace"
  #|  !$FNT = "Rec Mono Linear"
  #|
  #|' The preferred theme font
  #|  !$FNT = "Hack"
  #|
  #|!endif
  #|
  #|' Monospaced font
  #|!ifndef $FNT_MONO
  #|
  #|' A different font can be used
  #|' !$FNT_MONO = "Rec Mono Semicasual"
  #|  !$FNT_MONO = $FNT
  #|!endif
  #|
  #|' Theme body
  #|
  #|<style>
  #|  root {
  #|    BackgroundColor $CLR_BG
  #|    FontColor $CLR_FG
  #|    FontName $FNT
  #|    HyperLinkColor $CLR_HYPERLINK
  #|    LineColor $CLR_FG
  #|    LineThickness 1
  #|    Margin 5
  #|  }
  #|  document {
  #|    caption {
  #|      LineThickness 0
  #|    }
  #|    footer {
  #|      LineThickness 0
  #|    }
  #|    header {
  #|      LineThickness 0
  #|    }
  #|    title {
  #|      FontSize 22
  #|      LineThickness 0
  #|    }
  #|  }
  #|  node {
  #|'    MaximumWidth 300
  #|  }
  #|  ganttDiagram {
  #|    closed {
  #|      BackGroundColor $CLR_BG_EMPH
  #|    }
  #|    task {
  #|      BackGroundColor $CLR_FG_DIMMED_2
  #|      LineColor $CLR_FG
  #|      unstarted {
  #|        BackGroundColor $CLR_FG_DIMMED_3
  #|        LineColor $CLR_FG
  #|      }
  #|    }
  #|    note {
  #|      LineThickness .5
  #|    }
  #|    timeline {
  #|      LineThickness .5
  #|      LineColor $CLR_FG_DIMMED_3
  #|    }
  #|    separator {
  #|    }
  #|  }
  #|</style>
  #|
  #|' skinparam is flattened to support YAML, JSON diagram types
  #|skinparam {
  #|
  #|  shadowing false
  #|  useBetaStyle true
  #|  arrowLollipopColor $CLR_FG
  #|  backgroundColor $CLR_BG
  #|  lifelineStrategy nosolid
  #|
  #|  defaultFontName $FNT
  #|  defaultMonospacedFontName $FNT_MONO
  #|
  #|  hyperlinkColor $CLR_HYPERLINK
  #|
  #|  headerFontColor $CLR_FG_DIMMED_2
  #|  headerFontName $FNT
  #|
  #|  footerFontColor $CLR_FG_DIMMED_2
  #|  footerFontName $FNT
  #|
  #|  legendBorderThickness 0
  #|  legendBorderColor transparent
  #|
  #|  noteFontColor $CLR_FG
  #|  noteFontName $FNT
  #|
  #|  packageBorderColor $CLR_FG
  #|  packageFontColor $CLR_FG
  #|  packageFontName $FNT
  #|
  #|  nodeStereotypeFontColor $CLR_FG_DIMMED
  #|  nodeStereotypeFontName $FNT
  #|  nodeStereotypeFontSize 10
  #|
  #|  componentStereotypeFontColor $CLR_FG_DIMMED
  #|  componentStereotypeFontName $FNT
  #|  componentStereotypeFontSize 10
  #|
  #|  participantPadding 10
  #|
  #|  actorStereotypeFontColor $CLR_FG_DIMMED
  #|  actorStereotypeFontName $FNT
  #|  actorStereotypeFontSize 10
  #|
  #|  useCaseStereoTypeFontColor $CLR_FG
  #|  useCaseStereoTypeFontName $FNT
  #|
  #|  classBackgroundColor $CLR_BG
  #|  classBorderColor $CLR_FG
  #|  classFontColor $CLR_FG
  #|  classFontName $FNT
  #|  classAttributeFontColor $CLR_FG
  #|  classAttributeFontName $FNT
  #|  classStereotypeFontColor $CLR_FG_DIMMED
  #|  classStereotypeFontName $FNT
  #|  classStereotypeFontSize 10
  #|
  #|  objectBorderColor $CLR_FG
  #|
  #|  activityBackgroundColor $CLR_BG
  #|  activityBarColor $CLR_FG
  #|  activityBorderColor $CLR_FG
  #|  activityFontColor $CLR_FG
  #|  activityFontName $FNT
  #|
  #|  sequenceLifeLineBorderColor $CLR_FG
  #|
  #|  stateBackgroundColor $CLR_BG
  #|  stateBorderColor $CLR_FG
  #|
  #|  boundaryFontColor $CLR_FG
  #|
  #|  boxPadding 5
  #|
  #|  circledCharacterFontColor $CLR_FG
  #|  circledCharacterFontName $FNT_MONO
  #|  circledCharacterFontSize 10
  #|  circledCharacterRadius 8
  #|
  #|  stereotypeFontColor $CLR_FG_DIMMED
  #|  stereotypeFontName $FNT
  #|  stereotypeFontSize 10
  #|  stereotypeABackgroundColor $CLR_BG
  #|  stereotypeABorderColor $CLR_FG
  #|  stereotypeCBackgroundColor $CLR_BG
  #|  stereotypeCBorderColor $CLR_FG
  #|  stereotypeEBackgroundColor $CLR_BG
  #|  stereotypeEBorderColor $CLR_FG
  #|  stereotypeIBackgroundColor $CLR_BG
  #|  stereotypeIBorderColor $CLR_FG
  #|  stereotypeNBackgroundColor $CLR_BG
  #|  stereotypeNBorderColor $CLR_FG
  #|
  #|  iconPackageColor $CLR_FG
  #|  iconPackageBackgroundColor $CLR_BG
  #|  iconPrivateColor $CLR_FG
  #|  iconPrivateBackgroundColor $CLR_BG
  #|  iconProtectedColor $CLR_FG
  #|  iconProtectedBackgroundColor $CLR_BG
  #|  iconPublicColor $CLR_FG
  #|  iconPublicBackgroundColor $CLR_BG
  #|
  #|}

///|
// name: plain
// display_name: Plain
// description: A simple black on white theme (with blue hyperlinks)
// author: Matthew Leather
// release:
// license:
// version:
// source:
// inspiration:
let builtin_theme_23 : String =
  #|
  #|!$THEME = "plain"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|  !$BGCOLOR = "white"
  #|!endif
  #|
  #|!if %not(%variable_exists("$FGCOLOR"))
  #|  !$FGCOLOR = "black"
  #|!endif
  #|
  #|!if %not(%variable_exists("$HYPERLINK_COLOR"))
  #|  !$HYPERLINK_COLOR = "blue"
  #|!endif
  #|
  #|!ifndef $FONT_NAME
  #|  !$FONT_NAME = "Verdana"
  #|!endif
  #|
  #|!ifndef $FONT_NAME_MONOSPACED
  #|  !$FONT_NAME_MONOSPACED = "Courier"
  #|!endif
  #|
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $FGCOLOR
  #|    FontName $FONT_NAME
  #|    HyperLinkColor $HYPERLINK_COLOR
  #|    LineColor $FGCOLOR
  #|    LineThickness 1
  #|    Margin 5
  #|  }
  #|  document {
  #|    caption {
  #|      LineThickness 0
  #|    }
  #|    footer {
  #|      LineThickness 0
  #|    }
  #|    header {
  #|      LineThickness 0
  #|    }
  #|    title {
  #|      FontSize 22
  #|      LineThickness 0
  #|    }
  #|  }
  #|  node {
  #|    MaximumWidth 300
  #|  }
  #|  participant {
  #|    Margin 5 10
  #|    Padding 5 5
  #|  }
  #|</style>
  #|
  #|skinparam ArrowLollipopColor $FGCOLOR
  #|skinparam BackgroundColor $BGCOLOR
  #|skinparam DefaultFontName $FONT_NAME
  #|skinparam DefaultMonospacedFontName $FONT_NAME_MONOSPACED
  #|skinparam LifelineStrategy nosolid
  #|skinparam SequenceLifeLineBorderColor $FGCOLOR
  #|skinparam Shadowing false
  #|skinparam UseBetaStyle true
  #|
  #|skinparam Activity {
  #|  BackgroundColor $BGCOLOR
  #|  BarColor $FGCOLOR
  #|  BorderColor $FGCOLOR
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Boundary {
  #|  FontColor $FGCOLOR
  #|}
  #|skinparam Box {
  #|  Padding 5
  #|}
  #|skinparam CircledCharacter {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME_MONOSPACED
  #|  Radius 9
  #|}
  #|skinparam Class {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam ClassAttribute {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam ClassStereotype {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Footer {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Header {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Hyperlink {
  #|  Color $HYPERLINK_COLOR
  #|}
  #|skinparam IconPackage {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam IconPrivate {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam IconProtected {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam IconPublic {
  #|  Color $FGCOLOR
  #|  BackgroundColor $BGCOLOR
  #|}
  #|skinparam Note {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam Object {
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam Package {
  #|  BorderColor $FGCOLOR
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}
  #|skinparam State {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeA {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeC {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeE {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeI {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam StereotypeN {
  #|  BackgroundColor $BGCOLOR
  #|  BorderColor $FGCOLOR
  #|}
  #|skinparam UseCaseStereoType {
  #|  FontColor $FGCOLOR
  #|  FontName $FONT_NAME
  #|}

///|
// name: reddress-darkblue
// display_name: Reddress Darkblue
// description: A dark blue style from "Red Dress"
// author: [Drakemor](https://github.com/Drakemor)
// release:
// license: MIT
// version:
// source: https://github.com/Drakemor/RedDress-PlantUML
// inspiration:
let builtin_theme_24 : String =
  #|
  #|!if (%not(%variable_exists("$FONTNAME")))
  #|!$FONTNAME = "Verdana"
  #|!endif
  #|
  #|!if (%not(%variable_exists("$FONTSIZE")))
  #|!$FONTSIZE = 11
  #|!endif
  #|
  #|skinparam backgroundColor 777
  #|!$ACCENT = "1a66c2"
  #|!$ACCENTDARK = "002642"
  #|skinparam stereotypeCBackgroundColor $ACCENT
  #|!$PRIMARYFONTCOLOR = "fff"
  #|!$SECONDARY = "aaa"
  #|!$ARROWCOLOR = "fff"
  #|!$ARROWFONTCOLOR = "bbb"
  #|!$BORDERCOLOR = "1b1b1b"
  #|!$BOXBG = "2e2e2e"
  #|!$LIGHTBORDERCOLOR = "767676"
  #|!$LIGHTBG = "575757"
  #|skinparam backgroundColor 777
  #|
  #|!procedure font_style()
  #|  fontColor $PRIMARYFONTCOLOR
  #|  fontName $FONTNAME
  #|  fontSize $FONTSIZE
  #|  stereotypeFontColor $SECONDARY
  #|  stereotypeFontSize $FONTSIZE
  #|!endprocedure
  #|
  #|!procedure basic_style()
  #|  backgroundColor $BOXBG
  #|  borderColor $BORDERCOLOR
  #|!endprocedure
  #|
  #|!procedure light_style()
  #|  backgroundColor $LIGHTBG
  #|  borderColor $LIGHTBORDERCOLOR
  #|!endprocedure
  #|
  #|!procedure accent_style()
  #|  backgroundColor $ACCENT
  #|  borderColor $ACCENTDARK
  #|!endprocedure
  #|
  #|!procedure arrow_style()
  #|  arrowColor $ARROWCOLOR
  #|  arrowFontName $FONTNAME
  #|  arrowFontColor $ARROWFONTCOLOR
  #|  arrowFontSize $FONTSIZE
  #|!endprocedure
  #|
  #|' Class diagrams
  #|
  #|skinparam circledCharacter {
  #|  radius 8
  #|  fontSize $FONTSIZE
  #|  fontName $FONTNAME
  #|}
  #|
  #|skinparam class {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|
  #|  attributeFontColor $SECONDARY
  #|  attributeFontSize $FONTSIZE
  #|  attributeIconSize $FONTSIZE
  #|}
  #|
  #|' Sequence diagrams
  #|
  #|skinparam actor {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam participant {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam collections {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam SequenceBox{
  #|  light_style()
  #|  font_style()
  #|}
  #|
  #|' Component diagrams
  #|
  #|skinparam interface {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam component {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam node {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam database {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam queue {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|' Use Case diagrams
  #|
  #|skinparam usecase {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam activity {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam sequence {
  #|  font_style()
  #|  arrow_style()
  #|
  #|  lifeLineBorderColor $ACCENT
  #|  lifeLineBackgroundColor $LIGHTBG
  #|}
  #|
  #|skinparam boundary {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam control {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam entity {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|' State diagrams
  #|
  #|skinparam state {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|  startColor $ACCENT
  #|  endColor $ACCENTDARK
  #|}
  #|
  #|' Object diagrams
  #|
  #|skinparam object {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|' Common
  #|
  #|skinparam note {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam cloud {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam rectangle {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam storage {
  #|  basic_style()
  #|  font_style()
  #|}

///|
// name: reddress-darkgreen
// display_name: Reddress Darkgreen
// description: A dark green style from "Red Dress"
// author: [Drakemor](https://github.com/Drakemor)
// release:
// license: MIT
// version:
// source: https://github.com/Drakemor/RedDress-PlantUML
// inspiration:
let builtin_theme_25 : String =
  #|
  #|!if (%not(%variable_exists("$FONTNAME")))
  #|!$FONTNAME = "Verdana"
  #|!endif
  #|
  #|!if (%not(%variable_exists("$FONTSIZE")))
  #|!$FONTSIZE = 11
  #|!endif
  #|
  #|!$ACCENT = "228811"
  #|!$ACCENTDARK = "113300"
  #|skinparam stereotypeCBackgroundColor $ACCENT
  #|!$PRIMARYFONTCOLOR = "fff"
  #|!$SECONDARY = "aaa"
  #|!$ARROWCOLOR = "fff"
  #|!$ARROWFONTCOLOR = "bbb"
  #|!$BORDERCOLOR = "1b1b1b"
  #|!$BOXBG = "2e2e2e"
  #|!$LIGHTBORDERCOLOR = "767676"
  #|!$LIGHTBG = "575757"
  #|skinparam backgroundColor 777
  #|
  #|!procedure font_style()
  #|  fontColor $PRIMARYFONTCOLOR
  #|  fontName $FONTNAME
  #|  fontSize $FONTSIZE
  #|  stereotypeFontColor $SECONDARY
  #|  stereotypeFontSize $FONTSIZE
  #|!endprocedure
  #|
  #|!procedure basic_style()
  #|  backgroundColor $BOXBG
  #|  borderColor $BORDERCOLOR
  #|!endprocedure
  #|
  #|!procedure light_style()
  #|  backgroundColor $LIGHTBG
  #|  borderColor $LIGHTBORDERCOLOR
  #|!endprocedure
  #|
  #|!procedure accent_style()
  #|  backgroundColor $ACCENT
  #|  borderColor $ACCENTDARK
  #|!endprocedure
  #|
  #|!procedure arrow_style()
  #|  arrowColor $ARROWCOLOR
  #|  arrowFontName $FONTNAME
  #|  arrowFontColor $ARROWFONTCOLOR
  #|  arrowFontSize $FONTSIZE
  #|!endprocedure
  #|
  #|' Class diagrams
  #|
  #|skinparam circledCharacter {
  #|  radius 8
  #|  fontSize $FONTSIZE
  #|  fontName $FONTNAME
  #|}
  #|
  #|skinparam class {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|
  #|  attributeFontColor $SECONDARY
  #|  attributeFontSize $FONTSIZE
  #|  attributeIconSize $FONTSIZE
  #|}
  #|
  #|' Sequence diagrams
  #|
  #|skinparam actor {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam participant {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam collections {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam SequenceBox{
  #|  light_style()
  #|  font_style()
  #|}
  #|
  #|' Component diagrams
  #|
  #|skinparam interface {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam component {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam node {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam database {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam queue {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|' Use Case diagrams
  #|
  #|skinparam usecase {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam activity {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam sequence {
  #|  font_style()
  #|  arrow_style()
  #|
  #|  lifeLineBorderColor $ACCENT
  #|  lifeLineBackgroundColor $LIGHTBG
  #|}
  #|
  #|skinparam boundary {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam control {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam entity {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|' State diagrams
  #|
  #|skinparam state {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|  startColor $ACCENT
  #|  endColor $ACCENTDARK
  #|}
  #|
  #|' Object diagrams
  #|
  #|skinparam object {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|' Common
  #|
  #|skinparam note {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam cloud {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam rectangle {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam storage {
  #|  basic_style()
  #|  font_style()
  #|}

///|
// name: reddress-darkorange
// display_name: Reddress Darkorange
// description: A dark orange style from "Red Dress"
// author: [Drakemor](https://github.com/Drakemor)
// release:
// license: MIT
// version:
// source: https://github.com/Drakemor/RedDress-PlantUML
// inspiration:
let builtin_theme_26 : String =
  #|
  #|!if (%not(%variable_exists("$FONTNAME")))
  #|!$FONTNAME = "Verdana"
  #|!endif
  #|
  #|!if (%not(%variable_exists("$FONTSIZE")))
  #|!$FONTSIZE = 11
  #|!endif
  #|
  #|!$ACCENT = "BB6600"
  #|!$ACCENTDARK = "662200"
  #|skinparam stereotypeCBackgroundColor $ACCENT
  #|!$PRIMARYFONTCOLOR = "fff"
  #|!$SECONDARY = "aaa"
  #|!$ARROWCOLOR = "fff"
  #|!$ARROWFONTCOLOR = "bbb"
  #|!$BORDERCOLOR = "1b1b1b"
  #|!$BOXBG = "2e2e2e"
  #|!$LIGHTBORDERCOLOR = "767676"
  #|!$LIGHTBG = "575757"
  #|skinparam backgroundColor 777
  #|
  #|!procedure font_style()
  #|  fontColor $PRIMARYFONTCOLOR
  #|  fontName $FONTNAME
  #|  fontSize $FONTSIZE
  #|  stereotypeFontColor $SECONDARY
  #|  stereotypeFontSize $FONTSIZE
  #|!endprocedure
  #|
  #|!procedure basic_style()
  #|  backgroundColor $BOXBG
  #|  borderColor $BORDERCOLOR
  #|!endprocedure
  #|
  #|!procedure light_style()
  #|  backgroundColor $LIGHTBG
  #|  borderColor $LIGHTBORDERCOLOR
  #|!endprocedure
  #|
  #|!procedure accent_style()
  #|  backgroundColor $ACCENT
  #|  borderColor $ACCENTDARK
  #|!endprocedure
  #|
  #|!procedure arrow_style()
  #|  arrowColor $ARROWCOLOR
  #|  arrowFontName $FONTNAME
  #|  arrowFontColor $ARROWFONTCOLOR
  #|  arrowFontSize $FONTSIZE
  #|!endprocedure
  #|
  #|' Class diagrams
  #|
  #|skinparam circledCharacter {
  #|  radius 8
  #|  fontSize $FONTSIZE
  #|  fontName $FONTNAME
  #|}
  #|
  #|skinparam class {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|
  #|  attributeFontColor $SECONDARY
  #|  attributeFontSize $FONTSIZE
  #|  attributeIconSize $FONTSIZE
  #|}
  #|
  #|' Sequence diagrams
  #|
  #|skinparam actor {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam participant {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam collections {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam SequenceBox{
  #|  light_style()
  #|  font_style()
  #|}
  #|
  #|' Component diagrams
  #|
  #|skinparam interface {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam component {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam node {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam database {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam queue {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|' Use Case diagrams
  #|
  #|skinparam usecase {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam activity {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam sequence {
  #|  font_style()
  #|  arrow_style()
  #|
  #|  lifeLineBorderColor $ACCENT
  #|  lifeLineBackgroundColor $LIGHTBG
  #|}
  #|
  #|skinparam boundary {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam control {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam entity {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|' State diagrams
  #|
  #|skinparam state {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|  startColor $ACCENT
  #|  endColor $ACCENTDARK
  #|}
  #|
  #|' Object diagrams
  #|
  #|skinparam object {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|' Common
  #|
  #|skinparam note {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam cloud {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam rectangle {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam storage {
  #|  basic_style()
  #|  font_style()
  #|}

///|
// name: reddress-darkred
// display_name: Reddress Darkred
// description: A dark red style from "Red Dress"
// author: [Drakemor](https://github.com/Drakemor)
// release:
// license: MIT
// version:
// source: https://github.com/Drakemor/RedDress-PlantUML
// inspiration:
let builtin_theme_27 : String =
  #|
  #|!if (%not(%variable_exists("$FONTNAME")))
  #|!$FONTNAME = "Verdana"
  #|!endif
  #|
  #|!if (%not(%variable_exists("$FONTSIZE")))
  #|!$FONTSIZE = 11
  #|!endif
  #|
  #|!$ACCENT = "880000"
  #|!$ACCENTDARK = "330000"
  #|skinparam stereotypeCBackgroundColor $ACCENT
  #|!$PRIMARYFONTCOLOR = "fff"
  #|!$SECONDARY = "aaa"
  #|!$ARROWCOLOR = "fff"
  #|!$ARROWFONTCOLOR = "bbb"
  #|!$BORDERCOLOR = "1b1b1b"
  #|!$BOXBG = "2e2e2e"
  #|!$LIGHTBORDERCOLOR = "767676"
  #|!$LIGHTBG = "575757"
  #|skinparam backgroundColor 777
  #|
  #|!procedure font_style()
  #|  fontColor $PRIMARYFONTCOLOR
  #|  fontName $FONTNAME
  #|  fontSize $FONTSIZE
  #|  stereotypeFontColor $SECONDARY
  #|  stereotypeFontSize $FONTSIZE
  #|!endprocedure
  #|
  #|!procedure basic_style()
  #|  backgroundColor $BOXBG
  #|  borderColor $BORDERCOLOR
  #|!endprocedure
  #|
  #|!procedure light_style()
  #|  backgroundColor $LIGHTBG
  #|  borderColor $LIGHTBORDERCOLOR
  #|!endprocedure
  #|
  #|!procedure accent_style()
  #|  backgroundColor $ACCENT
  #|  borderColor $ACCENTDARK
  #|!endprocedure
  #|
  #|!procedure arrow_style()
  #|  arrowColor $ARROWCOLOR
  #|  arrowFontName $FONTNAME
  #|  arrowFontColor $ARROWFONTCOLOR
  #|  arrowFontSize $FONTSIZE
  #|!endprocedure
  #|
  #|' Class diagrams
  #|
  #|skinparam circledCharacter {
  #|  radius 8
  #|  fontSize $FONTSIZE
  #|  fontName $FONTNAME
  #|}
  #|
  #|skinparam class {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|
  #|  attributeFontColor $SECONDARY
  #|  attributeFontSize $FONTSIZE
  #|  attributeIconSize $FONTSIZE
  #|}
  #|
  #|' Sequence diagrams
  #|
  #|skinparam actor {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam participant {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam collections {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam SequenceBox{
  #|  light_style()
  #|  font_style()
  #|}
  #|
  #|' Component diagrams
  #|
  #|skinparam interface {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam component {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam node {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam database {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam queue {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|' Use Case diagrams
  #|
  #|skinparam usecase {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam activity {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam sequence {
  #|  font_style()
  #|  arrow_style()
  #|
  #|  lifeLineBorderColor $ACCENT
  #|  lifeLineBackgroundColor $LIGHTBG
  #|}
  #|
  #|skinparam boundary {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam control {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam entity {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|' State diagrams
  #|
  #|skinparam state {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|  startColor $ACCENT
  #|  endColor $ACCENTDARK
  #|}
  #|
  #|' Object diagrams
  #|
  #|skinparam object {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|' Common
  #|
  #|skinparam note {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam cloud {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam rectangle {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam storage {
  #|  basic_style()
  #|  font_style()
  #|}

///|
// name: reddress-lightblue
// display_name: Reddress Lightblue
// description: A light blue style from "Red Dress"
// author: [Drakemor](https://github.com/Drakemor)
// release:
// license: MIT
// version:
// source: https://github.com/Drakemor/RedDress-PlantUML
// inspiration:
let builtin_theme_28 : String =
  #|
  #|!if (%not(%variable_exists("$FONTNAME")))
  #|!$FONTNAME = "Verdana"
  #|!endif
  #|
  #|!if (%not(%variable_exists("$FONTSIZE")))
  #|!$FONTSIZE = 11
  #|!endif
  #|
  #|!$ACCENT = "2a86e2"
  #|!$ACCENTDARK = "1a66c2"
  #|skinparam stereotypeCBackgroundColor $ACCENTDARK
  #|!$PRIMARYFONTCOLOR = "000"
  #|!$SECONDARY = "333"
  #|!$ARROWCOLOR = "000"
  #|!$ARROWFONTCOLOR = "333"
  #|!$BORDERCOLOR = "aaa"
  #|!$BOXBG = "ccc"
  #|!$LIGHTBORDERCOLOR = "cccccc"
  #|!$LIGHTBG = "e0e0e0"
  #|skinparam backgroundColor fff
  #|
  #|!procedure font_style()
  #|  fontColor $PRIMARYFONTCOLOR
  #|  fontName $FONTNAME
  #|  fontSize $FONTSIZE
  #|  stereotypeFontColor $SECONDARY
  #|  stereotypeFontSize $FONTSIZE
  #|!endprocedure
  #|
  #|!procedure basic_style()
  #|  backgroundColor $BOXBG
  #|  borderColor $BORDERCOLOR
  #|!endprocedure
  #|
  #|!procedure light_style()
  #|  backgroundColor $LIGHTBG
  #|  borderColor $LIGHTBORDERCOLOR
  #|!endprocedure
  #|
  #|!procedure accent_style()
  #|  backgroundColor $ACCENT
  #|  borderColor $ACCENTDARK
  #|!endprocedure
  #|
  #|!procedure arrow_style()
  #|  arrowColor $ARROWCOLOR
  #|  arrowFontName $FONTNAME
  #|  arrowFontColor $ARROWFONTCOLOR
  #|  arrowFontSize $FONTSIZE
  #|!endprocedure
  #|
  #|' Class diagrams
  #|
  #|skinparam circledCharacter {
  #|  radius 8
  #|  fontSize $FONTSIZE
  #|  fontName $FONTNAME
  #|}
  #|
  #|skinparam class {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|
  #|  attributeFontColor $SECONDARY
  #|  attributeFontSize $FONTSIZE
  #|  attributeIconSize $FONTSIZE
  #|}
  #|
  #|' Sequence diagrams
  #|
  #|skinparam actor {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam participant {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam collections {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam SequenceBox{
  #|  light_style()
  #|  font_style()
  #|}
  #|
  #|' Component diagrams
  #|
  #|skinparam interface {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam component {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam node {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam database {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam queue {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|' Use Case diagrams
  #|
  #|skinparam usecase {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam activity {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam sequence {
  #|  font_style()
  #|  arrow_style()
  #|
  #|  lifeLineBorderColor $ACCENT
  #|  lifeLineBackgroundColor $LIGHTBG
  #|}
  #|
  #|skinparam boundary {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam control {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam entity {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|' State diagrams
  #|
  #|skinparam state {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|  startColor $ACCENT
  #|  endColor $ACCENTDARK
  #|}
  #|
  #|' Object diagrams
  #|
  #|skinparam object {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|' Common
  #|
  #|skinparam note {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam cloud {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam rectangle {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam storage {
  #|  basic_style()
  #|  font_style()
  #|}

///|
// name: reddress-lightgreen
// display_name: Reddress Lightgreen
// description: A light green style from "Red Dress"
// author: [Drakemor](https://github.com/Drakemor)
// release:
// license: MIT
// version:
// source: https://github.com/Drakemor/RedDress-PlantUML
// inspiration:
let builtin_theme_29 : String =
  #|
  #|!if (%not(%variable_exists("$FONTNAME")))
  #|!$FONTNAME = "Verdana"
  #|!endif
  #|
  #|!if (%not(%variable_exists("$FONTSIZE")))
  #|!$FONTSIZE = 11
  #|!endif
  #|
  #|!$ACCENT = "55BB33"
  #|!$ACCENTDARK = "338822"
  #|skinparam stereotypeCBackgroundColor $ACCENTDARK
  #|!$PRIMARYFONTCOLOR = "000"
  #|!$SECONDARY = "333"
  #|!$ARROWCOLOR = "000"
  #|!$ARROWFONTCOLOR = "333"
  #|!$BORDERCOLOR = "aaa"
  #|!$BOXBG = "ccc"
  #|!$LIGHTBORDERCOLOR = "cccccc"
  #|!$LIGHTBG = "e0e0e0"
  #|skinparam backgroundColor fff
  #|
  #|!procedure font_style()
  #|  fontColor $PRIMARYFONTCOLOR
  #|  fontName $FONTNAME
  #|  fontSize $FONTSIZE
  #|  stereotypeFontColor $SECONDARY
  #|  stereotypeFontSize $FONTSIZE
  #|!endprocedure
  #|
  #|!procedure basic_style()
  #|  backgroundColor $BOXBG
  #|  borderColor $BORDERCOLOR
  #|!endprocedure
  #|
  #|!procedure light_style()
  #|  backgroundColor $LIGHTBG
  #|  borderColor $LIGHTBORDERCOLOR
  #|!endprocedure
  #|
  #|!procedure accent_style()
  #|  backgroundColor $ACCENT
  #|  borderColor $ACCENTDARK
  #|!endprocedure
  #|
  #|!procedure arrow_style()
  #|  arrowColor $ARROWCOLOR
  #|  arrowFontName $FONTNAME
  #|  arrowFontColor $ARROWFONTCOLOR
  #|  arrowFontSize $FONTSIZE
  #|!endprocedure
  #|
  #|' Class diagrams
  #|
  #|skinparam circledCharacter {
  #|  radius 8
  #|  fontSize $FONTSIZE
  #|  fontName $FONTNAME
  #|}
  #|
  #|skinparam class {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|
  #|  attributeFontColor $SECONDARY
  #|  attributeFontSize $FONTSIZE
  #|  attributeIconSize $FONTSIZE
  #|}
  #|
  #|' Sequence diagrams
  #|
  #|skinparam actor {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam participant {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam collections {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam SequenceBox{
  #|  light_style()
  #|  font_style()
  #|}
  #|
  #|' Component diagrams
  #|
  #|skinparam interface {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam component {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam node {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam database {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam queue {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|' Use Case diagrams
  #|
  #|skinparam usecase {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam activity {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam sequence {
  #|  font_style()
  #|  arrow_style()
  #|
  #|  lifeLineBorderColor $ACCENT
  #|  lifeLineBackgroundColor $LIGHTBG
  #|}
  #|
  #|skinparam boundary {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam control {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam entity {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|' State diagrams
  #|
  #|skinparam state {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|  startColor $ACCENT
  #|  endColor $ACCENTDARK
  #|}
  #|
  #|' Object diagrams
  #|
  #|skinparam object {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|' Common
  #|
  #|skinparam note {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam cloud {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam rectangle {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam storage {
  #|  basic_style()
  #|  font_style()
  #|}

///|
// name: reddress-lightorange
// display_name: Reddress Lightorange
// description: A light orange style from "Red Dress"
// author: [Drakemor](https://github.com/Drakemor)
// release:
// license: MIT
// version:
// source: https://github.com/Drakemor/RedDress-PlantUML
// inspiration:
let builtin_theme_30 : String =
  #|
  #|!if (%not(%variable_exists("$FONTNAME")))
  #|!$FONTNAME = "Verdana"
  #|!endif
  #|
  #|!if (%not(%variable_exists("$FONTSIZE")))
  #|!$FONTSIZE = 11
  #|!endif
  #|
  #|!$ACCENT = "FF8800"
  #|!$ACCENTDARK = "BB6600"
  #|skinparam stereotypeCBackgroundColor $ACCENT
  #|!$PRIMARYFONTCOLOR = "000"
  #|!$SECONDARY = "333"
  #|!$ARROWCOLOR = "000"
  #|!$ARROWFONTCOLOR = "333"
  #|!$BORDERCOLOR = "aaa"
  #|!$BOXBG = "ccc"
  #|!$LIGHTBORDERCOLOR = "cccccc"
  #|!$LIGHTBG = "e0e0e0"
  #|skinparam backgroundColor fff
  #|
  #|!procedure font_style()
  #|  fontColor $PRIMARYFONTCOLOR
  #|  fontName $FONTNAME
  #|  fontSize $FONTSIZE
  #|  stereotypeFontColor $SECONDARY
  #|  stereotypeFontSize $FONTSIZE
  #|!endprocedure
  #|
  #|!procedure basic_style()
  #|  backgroundColor $BOXBG
  #|  borderColor $BORDERCOLOR
  #|!endprocedure
  #|
  #|!procedure light_style()
  #|  backgroundColor $LIGHTBG
  #|  borderColor $LIGHTBORDERCOLOR
  #|!endprocedure
  #|
  #|!procedure accent_style()
  #|  backgroundColor $ACCENT
  #|  borderColor $ACCENTDARK
  #|!endprocedure
  #|
  #|!procedure arrow_style()
  #|  arrowColor $ARROWCOLOR
  #|  arrowFontName $FONTNAME
  #|  arrowFontColor $ARROWFONTCOLOR
  #|  arrowFontSize $FONTSIZE
  #|!endprocedure
  #|
  #|' Class diagrams
  #|
  #|skinparam circledCharacter {
  #|  radius 8
  #|  fontSize $FONTSIZE
  #|  fontName $FONTNAME
  #|}
  #|
  #|skinparam class {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|
  #|  attributeFontColor $SECONDARY
  #|  attributeFontSize $FONTSIZE
  #|  attributeIconSize $FONTSIZE
  #|}
  #|
  #|' Sequence diagrams
  #|
  #|skinparam actor {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam participant {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam collections {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam SequenceBox{
  #|  light_style()
  #|  font_style()
  #|}
  #|
  #|' Component diagrams
  #|
  #|skinparam interface {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam component {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam node {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam database {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam queue {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|' Use Case diagrams
  #|
  #|skinparam usecase {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam activity {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam sequence {
  #|  font_style()
  #|  arrow_style()
  #|
  #|  lifeLineBorderColor $ACCENT
  #|  lifeLineBackgroundColor $LIGHTBG
  #|}
  #|
  #|skinparam boundary {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam control {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam entity {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|' State diagrams
  #|
  #|skinparam state {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|  startColor $ACCENT
  #|  endColor $ACCENTDARK
  #|}
  #|
  #|' Object diagrams
  #|
  #|skinparam object {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|' Common
  #|
  #|skinparam note {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam cloud {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam rectangle {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam storage {
  #|  basic_style()
  #|  font_style()
  #|}

///|
// name: reddress-lightred
// display_name: Reddress Lightred
// description: A light red style from "Red Dress"
// author: [Drakemor](https://github.com/Drakemor)
// release:
// license: MIT
// version:
// source: https://github.com/Drakemor/RedDress-PlantUML
// inspiration:
let builtin_theme_31 : String =
  #|
  #|!if (%not(%variable_exists("$FONTNAME")))
  #|!$FONTNAME = "Verdana"
  #|!endif
  #|
  #|!if (%not(%variable_exists("$FONTSIZE")))
  #|!$FONTSIZE = 11
  #|!endif
  #|
  #|!$ACCENT = "CC0033"
  #|!$ACCENTDARK = "AA0033"
  #|skinparam stereotypeCBackgroundColor $ACCENTDARK
  #|!$PRIMARYFONTCOLOR = "000"
  #|!$SECONDARY = "333"
  #|!$ARROWCOLOR = "000"
  #|!$ARROWFONTCOLOR = "333"
  #|!$BORDERCOLOR = "aaa"
  #|!$BOXBG = "ccc"
  #|!$LIGHTBORDERCOLOR = "cccccc"
  #|!$LIGHTBG = "e0e0e0"
  #|skinparam backgroundColor fff
  #|
  #|!procedure font_style()
  #|  fontColor $PRIMARYFONTCOLOR
  #|  fontName $FONTNAME
  #|  fontSize $FONTSIZE
  #|  stereotypeFontColor $SECONDARY
  #|  stereotypeFontSize $FONTSIZE
  #|!endprocedure
  #|
  #|!procedure basic_style()
  #|  backgroundColor $BOXBG
  #|  borderColor $BORDERCOLOR
  #|!endprocedure
  #|
  #|!procedure light_style()
  #|  backgroundColor $LIGHTBG
  #|  borderColor $LIGHTBORDERCOLOR
  #|!endprocedure
  #|
  #|!procedure accent_style()
  #|  backgroundColor $ACCENT
  #|  borderColor $ACCENTDARK
  #|!endprocedure
  #|
  #|!procedure arrow_style()
  #|  arrowColor $ARROWCOLOR
  #|  arrowFontName $FONTNAME
  #|  arrowFontColor $ARROWFONTCOLOR
  #|  arrowFontSize $FONTSIZE
  #|!endprocedure
  #|
  #|' Class diagrams
  #|
  #|skinparam circledCharacter {
  #|  radius 8
  #|  fontSize $FONTSIZE
  #|  fontName $FONTNAME
  #|}
  #|
  #|skinparam class {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|
  #|  attributeFontColor $SECONDARY
  #|  attributeFontSize $FONTSIZE
  #|  attributeIconSize $FONTSIZE
  #|}
  #|
  #|' Sequence diagrams
  #|
  #|skinparam actor {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam participant {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam collections {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam SequenceBox{
  #|  light_style()
  #|  font_style()
  #|}
  #|
  #|' Component diagrams
  #|
  #|skinparam interface {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam component {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam node {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam database {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam queue {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|' Use Case diagrams
  #|
  #|skinparam usecase {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam activity {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam sequence {
  #|  font_style()
  #|  arrow_style()
  #|
  #|  lifeLineBorderColor $ACCENT
  #|  lifeLineBackgroundColor $LIGHTBG
  #|}
  #|
  #|skinparam boundary {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam control {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam entity {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|' State diagrams
  #|
  #|skinparam state {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|  startColor $ACCENT
  #|  endColor $ACCENTDARK
  #|}
  #|
  #|' Object diagrams
  #|
  #|skinparam object {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|' Common
  #|
  #|skinparam note {
  #|  accent_style()
  #|  font_style()
  #|}
  #|
  #|skinparam cloud {
  #|  basic_style()
  #|  font_style()
  #|  arrow_style()
  #|}
  #|
  #|skinparam rectangle {
  #|  basic_style()
  #|  font_style()
  #|}
  #|
  #|skinparam storage {
  #|  basic_style()
  #|  font_style()
  #|}

///|
// name: sandstone
// display_name: Sandstone
// description: Theme based off of the bootstrap theme of the same name
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration: https://bootswatch.com/sandstone/
let builtin_theme_32 : String =
  #|
  #|!$THEME = "sandstone"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "transparent"
  #|!endif
  #|
  #|skinparam backgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|
  #|''
  #|'' Colors taken from the css file of the BS theme
  #|''
  #|!$BLUE = "#325d88"
  #|!$INDIGO = "#6610f2"
  #|!$PURPLE = "#6f42c1"
  #|!$PINK = "#e83e8c"
  #|!$RED = "#d9534f"
  #|!$ORANGE = "#f47c3c"
  #|!$YELLOW = "#ffc107"
  #|!$GREEN = "#93c54b"
  #|!$TEAL = "#20c997"
  #|!$CYAN = "#29abe0"
  #|!$WHITE = "#fff"
  #|!$GRAY = "#8e8c84"
  #|!$GRAYDARK = "#3e3f3a"
  #|!$PRIMARY = "#325d88"
  #|!$SECONDARY = "#8e8c84"
  #|!$SUCCESS = "#93c54b"
  #|!$INFO = "#29abe0"
  #|!$WARNING = "#f47c3c"
  #|!$DANGER = "#d9534f"
  #|!$LIGHT = "#f8f5f0"
  #|!$DARK = "#3e3f3a"
  #|
  #|'' *_DARK = tint (lighter) of the main color of 80%
  #|''          where TINT is calculated by clr + (255-clr) * tint_factor
  #|'' *_LIGHT = shade (darker) of the main color of 80%
  #|''          and SHADE is calculated by clr * (1 - shade_factor)
  #|''
  #|!$FGCOLOR = $WHITE
  #|!$PRIMARY_DARK = "#2d547a"
  #|!$PRIMARY_LIGHT = "#476d94"
  #|!$PRIMARY_TEXT = $WHITE
  #|!$SECONDARY_DARK = "#807e77"
  #|!$SECONDARY_LIGHT = "#999890"
  #|!$SECONDARY_TEXT = $WHITE
  #|!$INFO_DARK = "#259aca"
  #|!$INFO_LIGHT = "#3eb3e3"
  #|!$INFO_TEXT = $WHITE
  #|!$SUCCESS_DARK = "#84b144"
  #|!$SUCCESS_LIGHT = "#9ecb5d"
  #|!$SUCCESS_TEXT = $WHITE
  #|!$WARNING_DARK = "#dc7036"
  #|!$WARNING_LIGHT = "#f58950"
  #|!$WARNING_TEXT = $WHITE
  #|!$DANGER_DARK = "#c34b47"
  #|!$DANGER_LIGHT = "#AE423F"
  #|!$DANGER_TEXT = $WHITE
  #|!$DARK_DARK = "#383934"
  #|!$DARK_LIGHT = "#51524e"
  #|!$LIGHT_DARK = "#dfddd8"
  #|!$LIGHT_LIGHT = "#f9f6f2"
  #|
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|
  #|!procedure $primary_scheme()
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY_DARK
  #|	BackgroundColor $PRIMARY
  #|!endprocedure
  #|''
  #|'' Style settings
  #|''
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $ORANGE
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|   Padding 15
  #|   roundcorner 20
  #|   BackgroundColor $PRIMARY-$PRIMARY_DARK
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY
  #|    FontColor $INFO
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $DARK
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|  }
  #|  nwdiagDiagram {
  #|	network {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontColor $PRIMARY_DARK
  #|	}
  #|	server {
  #|		$primary_scheme()
  #|	}
  #|	arrow {
  #|		FontColor $PRIMARY_DARK
  #|		LineColor $PRIMARY_DARK
  #|	}
  #|	group {
  #|		BackGroundColor $LIGHT
  #|		LineColor $LIGHT_DARK
  #|		LineThickness 2.0
  #|		Margin 5
  #|		Padding 5
  #|	}
  #|  }
  #|  participant {
  #|    Margin 5 40
  #|    Padding 15 20
  #|  }
  #|  ganttDiagram {
  #|	task {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		Margin 10 2 2 2
  #|		Padding 6
  #|	}
  #|	note {
  #|		FontColor $INFO_TEXT
  #|		LineColor $INFO_DARK
  #|		BackGroundColor $INFO
  #|	}
  #|	separator {
  #|		LineColor $SECONDARY
  #|		BackGroundColor $SECONDARY-$SECONDARY_DARK
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	milestone {
  #|		FontColor $INFO
  #|		FontSize 16
  #|		FontStyle italic
  #|		BackGroundColor $SECONDARY
  #|		LineColor $SECONDARY_DARK
  #|	}
  #|	timeline {
  #|		BackgroundColor $SECONDARY
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	closed {
  #|		BackgroundColor $WARNING_DARK
  #|		FontColor $WARNING_TEXT
  #|	}
  #|  }
  #|</style>
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName       "Verdana"
  #|skinparam defaultFontSize       12
  #|skinparam dpi                   100
  #|skinparam shadowing             false
  #|skinparam roundcorner           8
  #|skinparam BoxPadding            40
  #|skinparam ArrowColor            $DARK
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_LIGHT
  #|    CBorderColor $SECONDARY_DARK
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontColor	                 $PRIMARY
  #|	BorderColor	                 $SECONDARY_DARK
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor              $SECONDARY_LIGHT-$SECONDARY
  #|}
  #|
  #|skinparam legend {
  #|	BackgroundColor $SECONDARY
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $LIGHT
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $SECONDARY_LIGHT
  #|  	DiamondBorderColor $SECONDARY_DARK
  #|  	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|
  #|skinparam sequence {
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $BGCOLOR
  #|	BoxBorderColor $DARK
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $SECONDARY
  #|	LifeLineBorderThickness 2
  #|	LifeLineBackgroundColor $SECONDARY_DARK
  #|	''
  #|	GroupBorderColor $DARK
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO
  #|	GroupBackgroundColor $SECONDARY
  #|	GroupHeaderBackgroundColor $BGCOLOR
  #|	''
  #|	DividerBackgroundColor $DARK
  #|    DividerBorderColor $DARK
  #|    DividerBorderThickness 2
  #|    DividerFontColor $LIGHT
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceBorderColor $DARK
  #|	ReferenceFontColor $DARK
  #|	ReferenceHeaderFontColor $INFO
  #|	ReferenceHeaderBackgroundColor $SECONDARY
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|
  #|skinparam control {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|
  #|skinparam entity {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|
  #|skinparam boundary {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|
  #|skinparam agent {
  #|	BackgroundColor $WARNING
  #|	BorderColor $WARNING_LIGHT
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $INFO
  #|	BorderColor $INFO_DARK
  #|	FontColor $WHITE
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|
  #|skinparam artifact {
  #|	BackgroundColor $DARK
  #|	BorderColor $DARK_DARK
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|
  #|skinparam component {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|
  #|skinparam interface {
  #|	BackgroundColor  $DANGER_DARK
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|
  #|skinparam storage {
  #|	BackgroundColor $WARNING
  #|  	BorderColor $WARNING_DARK
  #|	FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|
  #|skinparam node {
  #|	BackgroundColor  $SECONDARY
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|
  #|skinparam cloud {
  #|	BackgroundColor #F2FCFE-#eeeeee
  #|	BorderColor #F2FCFE
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|
  #|skinparam database {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|
  #|skinparam class {
  #|	$primary_scheme()
  #|	HeaderBackgroundColor $PRIMARY_LIGHT
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $PRIMARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|
  #|skinparam rectangle {
  #|	$primary_scheme()
  #|	BackgroundColor $SECONDARY_LIGHT
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|
  #|skinparam package {
  #|	BackgroundColor $SECONDARY
  #|  	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|
  #|skinparam folder {
  #|	BackgroundColor $SECONDARY_LIGHT
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|
  #|skinparam frame {
  #|	BackgroundColor $SECONDARY_LIGHT
  #|  	BorderColor $INFO
  #|	FontColor $INFO
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|
  #|skinparam state {
  #|	$primary_scheme()
  #|	BackgroundColor $PRIMARY_LIGHT
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|
  #|skinparam card {
  #|	BackgroundColor $INFO
  #|	BorderColor $INFO_DARK
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|
  #|skinparam file {
  #|	BackgroundColor $SECONDARY_DARK
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub

///|
// name: silver
// display_name: Silver
// description: Mostly silver grays Theme
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration:
let builtin_theme_33 : String =
  #|
  #|!$THEME = "silver"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "transparent"
  #|!endif
  #|
  #|skinparam backgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|
  #|!$WHITE = "#FFF"
  #|!$GRAY_DARK = "#4d4d4d"
  #|!$GRAY = "#737373"
  #|!$LIGHT = "#ffffff"
  #|!$DARK = "#303030"
  #|
  #|'' *_LIGHT = tint (lighter) of the main color of 80%
  #|''          where TINT is calculated by clr + (255-clr) * tint_factor
  #|'' *_DARK = shade (darker) of the main color of 80%
  #|''          and SHADE is calculated by clr * (1 - shade_factor)
  #|''
  #|!$FGCOLOR = $DARK
  #|!$PRIMARY = "#eeeeee"
  #|!$PRIMARY_LIGHT = "#f1f1f1"
  #|!$PRIMARY_DARK = "#bebebe"
  #|!$PRIMARY_TEXT = "#336699"
  #|!$SECONDARY = "#d6d6d6"
  #|!$SECONDARY_LIGHT = "#dedede"
  #|!$SECONDARY_DARK = "#ababab"
  #|!$SECONDARY_TEXT = $LIGHT
  #|!$INFO = "#336699"
  #|!$INFO_LIGHT = "#5c85ad"
  #|!$INFO_DARK = "#29527a"
  #|!$INFO_TEXT = $WHITE
  #|!$SUCCESS = "#339933"
  #|!$SUCCESS_LIGHT = "#5cad5c"
  #|!$SUCCESS_DARK = "#297a29"
  #|!$SUCCESS_TEXT = $WHITE
  #|!$WARNING = "#ffae42"
  #|!$WARNING_LIGHT = "#ffbe68"
  #|!$WARNING_DARK = "#cc8b35"
  #|!$WARNING_TEXT = $WHITE
  #|!$DANGER = "#ff3333"
  #|!$DANGER_LIGHT = "#ff5c5c"
  #|!$DANGER_DARK = "#cc2929"
  #|!$DANGER_TEXT = $WHITE
  #|
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|
  #|!procedure $primary_scheme()
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY_LIGHT
  #|	BackgroundColor $PRIMARY-$PRIMARY_DARK
  #|!endprocedure
  #|''
  #|'' Style settings
  #|''
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $ORANGE
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|   Padding 15
  #|   roundcorner 20
  #|   BackgroundColor $PRIMARY-$PRIMARY_DARK
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY
  #|    FontColor $INFO
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $DARK
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|  }
  #|  nwdiagDiagram {
  #|	network {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontColor $PRIMARY_DARK
  #|	}
  #|	server {
  #|		$primary_scheme()
  #|	}
  #|	arrow {
  #|		FontColor $PRIMARY_DARK
  #|		LineColor $PRIMARY_DARK
  #|	}
  #|	group {
  #|		BackGroundColor $LIGHT
  #|		LineColor $LIGHT_DARK
  #|		LineThickness 2.0
  #|		Margin 5
  #|		Padding 5
  #|	}
  #|  }
  #|  participant {
  #|    Margin 5 30
  #|    Padding 15 20
  #|  }
  #|  ganttDiagram {
  #|	task {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		Margin 10 2 2 2
  #|		Padding 6
  #|	}
  #|	note {
  #|		FontColor $INFO_TEXT
  #|		LineColor $INFO_DARK
  #|		BackGroundColor $INFO
  #|	}
  #|	separator {
  #|		LineColor $SECONDARY
  #|		BackGroundColor $SECONDARY-$SECONDARY_DARK
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	milestone {
  #|		FontColor $INFO
  #|		FontSize 16
  #|		FontStyle italic
  #|		BackGroundColor $SECONDARY
  #|		LineColor $SECONDARY_DARK
  #|	}
  #|	timeline {
  #|		BackgroundColor $SECONDARY
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	closed {
  #|		BackgroundColor $WARNING_DARK
  #|		FontColor $WARNING_TEXT
  #|	}
  #|  }
  #|</style>
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName        "Verdana"
  #|skinparam defaultFontSize        12
  #|skinparam dpi                    100
  #|skinparam shadowing              false
  #|skinparam roundcorner            15
  #|skinparam BoxPadding             30
  #|skinparam ArrowColor             $GRAY
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_LIGHT
  #|    CBorderColor $SECONDARY_DARK
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontColor	                 $PRIMARY
  #|	BorderColor	                 $SECONDARY_DARK
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor              $SECONDARY_LIGHT-$SECONDARY
  #|}
  #|
  #|
  #|skinparam legend {
  #|	BackgroundColor $SECONDARY
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $SECONDARY_TEXT
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $SECONDARY-$SECONDARY_DARK
  #|  	DiamondBorderColor $SECONDARY_DARK
  #|	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|
  #|!endsub
  #|
  #|!startsub participant
  #|
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness 2
  #|}
  #|
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|
  #|!endsub
  #|
  #|!startsub arrow
  #|
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $FGCOLOR
  #|}
  #|
  #|!endsub
  #|
  #|!startsub sequence
  #|
  #|skinparam sequence {
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $LIGHT
  #|	BoxBorderColor $GRAY
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $SECONDARY_DARK
  #|	LifeLineBorderThickness 2
  #|	LifeLineBackgroundColor $SECONDARY_LIGHT
  #|	''
  #|	GroupBorderColor $GRAY
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO
  #|	''
  #|	DividerBackgroundColor $WHITE-$LIGHT
  #|    DividerBorderColor $GRAY
  #|    DividerBorderThickness 2
  #|    DividerFontColor $DARK
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceBorderColor $GRAY
  #|	ReferenceFontColor $DARK
  #|	ReferenceHeaderFontColor $INFO
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|
  #|!endsub
  #|
  #|!startsub partition
  #|
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY_DARK
  #|	BackgroundColor $BGCOLOR
  #|}
  #|
  #|!endsub
  #|
  #|!startsub collections
  #|
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|
  #|!endsub
  #|
  #|!startsub control
  #|
  #|skinparam control {
  #|	$primary_scheme()
  #|}
  #|
  #|!endsub
  #|
  #|!startsub entity
  #|
  #|skinparam entity {
  #|	$primary_scheme()
  #|}
  #|
  #|!endsub
  #|
  #|!startsub boundary
  #|
  #|skinparam boundary {
  #|	$primary_scheme()
  #|}
  #|
  #|!endsub
  #|
  #|!startsub agent
  #|
  #|skinparam agent {
  #|	BackgroundColor #orange
  #|	BorderColor #999999
  #|	FontColor #333333
  #|}
  #|
  #|!endsub
  #|
  #|!startsub note
  #|
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $INFO_LIGHT-$INFO
  #|	BorderColor $INFO
  #|	FontColor $WHITE
  #|}
  #|
  #|!endsub
  #|
  #|!startsub artifact
  #|
  #|skinparam artifact {
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY_DARK
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $SECONDARY_TEXT
  #|}
  #|
  #|!endsub
  #|
  #|!startsub component
  #|
  #|skinparam component {
  #|	$primary_scheme()
  #|}
  #|
  #|!endsub
  #|
  #|!startsub interface
  #|
  #|skinparam interface {
  #|	BackgroundColor  $DANGER_LIGHT
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|
  #|!endsub
  #|
  #|!startsub storage
  #|
  #|skinparam storage {
  #|	BackgroundColor $WARNING_LIGHT-$WARNING
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING_TEXT
  #|}
  #|
  #|!endsub
  #|
  #|!startsub node
  #|
  #|skinparam node {
  #|	BackgroundColor $PRIMARY_LIGHT-$PRIMARY_DARK
  #|	BorderColor $PRIMARY_LIGHT
  #|	FontColor $PRIMARY_TEXT
  #|}
  #|
  #|!endsub
  #|
  #|!startsub cloud
  #|
  #|skinparam cloud {
  #|	BackgroundColor #F2FCFE-#eeeeee
  #|	BorderColor #F2FCFE
  #|	FontColor $DARK
  #|}
  #|
  #|!endsub
  #|
  #|!startsub database
  #|
  #|skinparam database {
  #|	$primary_scheme()
  #|	FontColor $DARK
  #|}
  #|
  #|!endsub
  #|
  #|!startsub class
  #|
  #|skinparam class {
  #|	$primary_scheme()
  #|	HeaderBackgroundColor $PRIMARY_LIGHT-$PRIMARY_DARK
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $DARK
  #|	AttributeFontSize 9
  #|}
  #|
  #|!endsub
  #|
  #|!startsub object
  #|
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $LIGHT
  #|	BorderThickness 1
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|
  #|!endsub
  #|
  #|!startsub usecase
  #|
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|
  #|!endsub
  #|
  #|!startsub rectangle
  #|
  #|skinparam rectangle {
  #|	$primary_scheme()
  #|	BackgroundColor $PRIMARY_LIGHT
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|
  #|!endsub
  #|
  #|!startsub package
  #|
  #|skinparam package {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|}
  #|
  #|!endsub
  #|
  #|!startsub folder
  #|
  #|skinparam folder {
  #|	BackgroundColor $PRIMARY-$PRIMARY_DARK
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|
  #|!endsub
  #|
  #|!startsub frame
  #|
  #|skinparam frame {
  #|	BackgroundColor $PRIMARY-$PRIMARY_DARK
  #|  	BorderColor $INFO
  #|	FontColor $INFO
  #|	BorderThickness 2
  #|}
  #|
  #|!endsub
  #|
  #|!startsub state
  #|
  #|skinparam state {
  #|	$primary_scheme()
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|
  #|!endsub
  #|
  #|!startsub queue
  #|
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|
  #|!endsub
  #|
  #|!startsub card
  #|
  #|skinparam card {
  #|	BackgroundColor $INFO_LIGHT-$INFO
  #|	BorderColor $INFO
  #|	FontColor $INFO_TEXT
  #|}
  #|
  #|!endsub
  #|
  #|!startsub file
  #|
  #|skinparam file {
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|
  #|}
  #|
  #|!endsub
  #|
  #|!startsub stack
  #|
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|
  #|!endsub

///|
// name: sketchy-outline
// display_name: Sketchy Outline
// description: Theme based off of the bootstrap theme of the same name, with outline colors
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration: https://bootswatch.com/sketchy/
let builtin_theme_34 : String =
  #|
  #|!$THEME = "sketchy-outline"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "transparent"
  #|!endif
  #|
  #|skinparam backgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|!option handwritten true
  #|skinparam shadowing false
  #|
  #|''
  #|'' Colors taken from the css file of the BS theme
  #|''
  #|!$BLUE = "#007bff"
  #|!$INDIGO = "#6610f2"
  #|!$PURPLE = "#6f42c1"
  #|!$PINK = "#e83e8c"
  #|!$RED = "#dc3545"
  #|!$ORANGE = "#fd7e14"
  #|!$YELLOW = "#ffc107"
  #|!$GREEN = "#28a745"
  #|!$TEAL = "#20c997"
  #|!$CYAN = "#17a2b8"
  #|!$WHITE = "#ffffff"
  #|!$GRAY = "#868e96"
  #|!$GRAYDARK = "#333333"
  #|!$PRIMARY = "#333333"
  #|!$SECONDARY = "#555555"
  #|!$SUCCESS = "#28a745"
  #|!$INFO = "#17a2b8"
  #|!$WARNING = "#ffc107"
  #|!$DANGER = "#dc3545"
  #|!$LIGHT = "#ffffff"
  #|!$DARK = "#555555"
  #|
  #|'' *_DARK = tint (lighter) of the main color of 80%
  #|''          where TINT is calculated by clr + (255-clr) * tint_factor
  #|'' *_LIGHT = shade (darker) of the main color of 80%
  #|''          and SHADE is calculated by clr * (1 - shade_factor)
  #|''
  #|!$FGCOLOR = $WHITE
  #|!$PRIMARY_DARK = "#2e2e2e"
  #|!$PRIMARY_LIGHT = "#474747"
  #|!$PRIMARY_TEXT = "#2e2e2e"
  #|!$SECONDARY_DARK = "#4d4d4d"
  #|!$SECONDARY_LIGHT = "#666666"
  #|!$SECONDARY_TEXT = $WHITE
  #|!$INFO_DARK = "#1592a6"
  #|!$INFO_LIGHT = "#2eabbf"
  #|!$INFO_TEXT = $WHITE
  #|!$SUCCESS_DARK = "#24963e"
  #|!$SUCCESS_LIGHT = "#3eb058"
  #|!$SUCCESS_TEXT = $WHITE
  #|!$WARNING_DARK = "#e6ae06"
  #|!$WARNING_LIGHT = "#ffc720"
  #|!$WARNING_TEXT = $WHITE
  #|!$DANGER_DARK = "#c6303e"
  #|!$DANGER_LIGHT = "#e04958"
  #|!$DANGER_TEXT = $WHITE
  #|!$DARK_DARK = "#4d4d4d"
  #|!$DARK_LIGHT = "#666666"
  #|!$LIGHT_DARK = "#e6e6e6"
  #|!$LIGHT_LIGHT = "#ffffff"
  #|
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|
  #|!procedure $primary_scheme()
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|!endprocedure
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $ORANGE
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|   Padding 15
  #|   roundcorner 20
  #|   BackgroundColor $BGCOLOR
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY
  #|    FontColor $INFO
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $DARK
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $BGCOLOR
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|  }
  #|  nwdiagDiagram {
  #|	network {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontColor $PRIMARY_DARK
  #|	}
  #|	server {
  #|		$primary_scheme()
  #|	}
  #|	arrow {
  #|		FontColor $PRIMARY_DARK
  #|		LineColor $PRIMARY_DARK
  #|	}
  #|	group {
  #|		BackGroundColor $LIGHT
  #|		LineColor $LIGHT_DARK
  #|		LineThickness 2.0
  #|		Margin 5
  #|		Padding 5
  #|	}
  #|  }
  #|  participant {
  #|    Margin 5 40
  #|    Padding 15 20
  #|  }
  #|  ganttDiagram {
  #|	task {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		Margin 10 2 2 2
  #|		Padding 6
  #|	}
  #|	note {
  #|		FontColor $INFO_TEXT
  #|		LineColor $INFO_DARK
  #|		BackGroundColor $BGCOLOR
  #|	}
  #|	separator {
  #|		LineColor $SECONDARY_DARK
  #|		BackGroundColor $BGCOLOR
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	milestone {
  #|		FontColor $INFO
  #|		FontSize 16
  #|		FontStyle italic
  #|		BackGroundColor $SECONDARY
  #|		LineColor $SECONDARY_DARK
  #|	}
  #|	timeline {
  #|		BackgroundColor $SECONDARY
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	closed {
  #|		BackgroundColor $WARNING_DARK
  #|		FontColor $WARNING_TEXT
  #|	}
  #|  }
  #|</style>
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName       "Segoe Print"
  #|skinparam defaultFontSize       12
  #|skinparam dpi                   100
  #|skinparam shadowing             false
  #|skinparam roundcorner           8
  #|skinparam BoxPadding            40
  #|skinparam ArrowColor            $DARK
  #|skinparam stereotype {
  #|    CBackgroundColor $BGCOLOR
  #|    CBorderColor $SECONDARY_DARK
  #|    ABackgroundColor $BGCOLOR
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $BGCOLOR
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $BGCOLOR
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $BGCOLOR
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontColor	                 $PRIMARY_TEXT
  #|	BorderColor	                 $SECONDARY_DARK
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor              $BGCOLOR
  #|}
  #|
  #|skinparam legend {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $PRIMARY_TEXT
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $BGCOLOR
  #|	TitleFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $BGCOLOR
  #|  	DiamondBorderColor $SECONDARY_DARK
  #|  	DiamondFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|
  #|skinparam sequence {
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $PRIMARY_TEXT
  #|	BackgroundColor $BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $BGCOLOR
  #|	BoxBorderColor $DARK
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $SECONDARY
  #|	LifeLineBorderThickness 2
  #|	LifeLineBackgroundColor $SECONDARY_DARK
  #|	''
  #|	GroupBorderColor $DARK
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO
  #|	GroupBackgroundColor $SECONDARY
  #|	GroupHeaderBackgroundColor $BGCOLOR
  #|	''
  #|	DividerBackgroundColor $DARK
  #|    DividerBorderColor $DARK
  #|    DividerBorderThickness 2
  #|    DividerFontColor $LIGHT
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceBorderColor $DARK
  #|	ReferenceFontColor $DARK
  #|	ReferenceHeaderFontColor $INFO
  #|	ReferenceHeaderBackgroundColor $SECONDARY
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|
  #|skinparam control {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|
  #|skinparam entity {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|
  #|skinparam boundary {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|
  #|skinparam agent {
  #|	BackgroundColor $WARNING
  #|	BorderColor $WARNING_LIGHT
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $INFO
  #|	BorderColor $INFO_DARK
  #|	FontColor $WHITE
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|
  #|skinparam artifact {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $DARK_DARK
  #|	FontColor $DARK_DARK
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|
  #|skinparam component {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|
  #|skinparam interface {
  #|	BackgroundColor  $BGCOLOR
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|
  #|skinparam storage {
  #|	BackgroundColor $BGCOLOR
  #|  	BorderColor $WARNING_DARK
  #|	FontColor $WARNING_DARK
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|
  #|skinparam node {
  #|	BackgroundColor  $BGCOLOR
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|
  #|skinparam cloud {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor #F2FCFE
  #|	FontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|
  #|skinparam database {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|
  #|skinparam class {
  #|	$primary_scheme()
  #|	HeaderBackgroundColor $BGCOLOR
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $DARK
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|	BorderThickness 1
  #|	AttributeFontColor $PRIMARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|
  #|skinparam rectangle {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|
  #|skinparam package {
  #|	BackgroundColor $BGCOLOR
  #|  	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|
  #|skinparam folder {
  #|	BackgroundColor $BGCOLOR
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|
  #|skinparam frame {
  #|	BackgroundColor $BGCOLOR
  #|  	BorderColor $INFO
  #|	FontColor $INFO
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|
  #|skinparam state {
  #|	$primary_scheme()
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|
  #|skinparam card {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $INFO_DARK
  #|	FontColor $INFO_DARK
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|
  #|skinparam file {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub

///|
// name: sketchy
// display_name: Sketchy
// description: Theme based off of the bootstrap theme of the same name
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration: https://bootswatch.com/sketchy/
let builtin_theme_35 : String =
  #|
  #|!$THEME = "sketchy"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "transparent"
  #|!endif
  #|
  #|skinparam backgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|!option handwritten true
  #|skinparam shadowing false
  #|
  #|''
  #|'' Colors taken from the css file of the BS theme
  #|''
  #|!$BLUE = "#007bff"
  #|!$INDIGO = "#6610f2"
  #|!$PURPLE = "#6f42c1"
  #|!$PINK = "#e83e8c"
  #|!$RED = "#dc3545"
  #|!$ORANGE = "#fd7e14"
  #|!$YELLOW = "#ffc107"
  #|!$GREEN = "#28a745"
  #|!$TEAL = "#20c997"
  #|!$CYAN = "#17a2b8"
  #|!$WHITE = "#ffffff"
  #|!$GRAY = "#868e96"
  #|!$GRAYDARK = "#333333"
  #|!$PRIMARY = "#333333"
  #|!$SECONDARY = "#555555"
  #|!$SUCCESS = "#28a745"
  #|!$INFO = "#17a2b8"
  #|!$WARNING = "#ffc107"
  #|!$DANGER = "#dc3545"
  #|!$LIGHT = "#ffffff"
  #|!$DARK = "#555555"
  #|
  #|'' *_DARK = tint (lighter) of the main color of 80%
  #|''          where TINT is calculated by clr + (255-clr) * tint_factor
  #|'' *_LIGHT = shade (darker) of the main color of 80%
  #|''          and SHADE is calculated by clr * (1 - shade_factor)
  #|''
  #|!$FGCOLOR = $WHITE
  #|!$PRIMARY_DARK = "#2e2e2e"
  #|!$PRIMARY_LIGHT = "#474747"
  #|!$PRIMARY_TEXT = $WHITE
  #|!$SECONDARY_DARK = "#4d4d4d"
  #|!$SECONDARY_LIGHT = "#666666"
  #|!$SECONDARY_TEXT = $WHITE
  #|!$INFO_DARK = "#1592a6"
  #|!$INFO_LIGHT = "#2eabbf"
  #|!$INFO_TEXT = $WHITE
  #|!$SUCCESS_DARK = "#24963e"
  #|!$SUCCESS_LIGHT = "#3eb058"
  #|!$SUCCESS_TEXT = $WHITE
  #|!$WARNING_DARK = "#e6ae06"
  #|!$WARNING_LIGHT = "#ffc720"
  #|!$WARNING_TEXT = $WHITE
  #|!$DANGER_DARK = "#c6303e"
  #|!$DANGER_LIGHT = "#e04958"
  #|!$DANGER_TEXT = $WHITE
  #|!$DARK_DARK = "#4d4d4d"
  #|!$DARK_LIGHT = "#666666"
  #|!$LIGHT_DARK = "#e6e6e6"
  #|!$LIGHT_LIGHT = "#ffffff"
  #|
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|
  #|!procedure $primary_scheme()
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY
  #|	BackgroundColor $PRIMARY_LIGHT
  #|!endprocedure
  #|''
  #|'' Style settings
  #|''
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $ORANGE
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|   Padding 15
  #|   roundcorner 20
  #|   BackgroundColor $PRIMARY-$PRIMARY_DARK
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY
  #|    FontColor $INFO
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $DARK
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|  }
  #|  nwdiagDiagram {
  #|	network {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontColor $PRIMARY_DARK
  #|	}
  #|	server {
  #|		$primary_scheme()
  #|	}
  #|	arrow {
  #|		FontColor $PRIMARY_DARK
  #|		LineColor $PRIMARY_DARK
  #|	}
  #|	group {
  #|		BackGroundColor $LIGHT
  #|		LineColor $LIGHT_DARK
  #|		LineThickness 2.0
  #|		Margin 5
  #|		Padding 5
  #|	}
  #|  }
  #|  participant {
  #|    Margin 5 40
  #|    Padding 15 20
  #|  }
  #|  ganttDiagram {
  #|	task {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		Margin 10 2 2 2
  #|		Padding 6
  #|	}
  #|	note {
  #|		FontColor $INFO_TEXT
  #|		LineColor $INFO_DARK
  #|		BackGroundColor $INFO
  #|	}
  #|	separator {
  #|		LineColor $SECONDARY
  #|		BackGroundColor $SECONDARY-$SECONDARY_DARK
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	milestone {
  #|		FontColor $INFO
  #|		FontSize 16
  #|		FontStyle italic
  #|		BackGroundColor $SECONDARY
  #|		LineColor $SECONDARY_DARK
  #|	}
  #|	timeline {
  #|		BackgroundColor $SECONDARY
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	closed {
  #|		BackgroundColor $WARNING_DARK
  #|		FontColor $WARNING_TEXT
  #|	}
  #|  }
  #|</style>
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName       "Segoe Print"
  #|skinparam defaultFontSize       12
  #|skinparam dpi                   100
  #|skinparam shadowing             false
  #|skinparam roundcorner           8
  #|skinparam BoxPadding            40
  #|skinparam ArrowColor            $DARK
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_LIGHT
  #|    CBorderColor $SECONDARY_DARK
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontColor	                 $FGCOLOR
  #|	BorderColor	                 $SECONDARY_DARK
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor              $SECONDARY_LIGHT-$SECONDARY
  #|}
  #|
  #|skinparam legend {
  #|	BackgroundColor $SECONDARY
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $LIGHT
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $SECONDARY_LIGHT
  #|  	DiamondBorderColor $SECONDARY_DARK
  #|  	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|
  #|skinparam sequence {
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $BGCOLOR
  #|	BoxBorderColor $DARK
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $SECONDARY
  #|	LifeLineBorderThickness 2
  #|	LifeLineBackgroundColor $SECONDARY_DARK
  #|	''
  #|	GroupBorderColor $DARK
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO
  #|	GroupBackgroundColor $SECONDARY
  #|	GroupHeaderBackgroundColor $BGCOLOR
  #|	''
  #|	DividerBackgroundColor $DARK
  #|    DividerBorderColor $DARK
  #|    DividerBorderThickness 2
  #|    DividerFontColor $LIGHT
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceBorderColor $DARK
  #|	ReferenceFontColor $DARK
  #|	ReferenceHeaderFontColor $INFO
  #|	ReferenceHeaderBackgroundColor $SECONDARY
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|
  #|skinparam control {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|
  #|skinparam entity {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|
  #|skinparam boundary {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|
  #|skinparam agent {
  #|	BackgroundColor $WARNING
  #|	BorderColor $WARNING_LIGHT
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $INFO
  #|	BorderColor $INFO_DARK
  #|	FontColor $WHITE
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|
  #|skinparam artifact {
  #|	BackgroundColor $DARK
  #|	BorderColor $DARK_DARK
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|
  #|skinparam component {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|
  #|skinparam interface {
  #|	BackgroundColor  $DANGER_DARK
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|
  #|skinparam storage {
  #|	BackgroundColor $WARNING
  #|  	BorderColor $WARNING_DARK
  #|	FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|
  #|skinparam node {
  #|	BackgroundColor  $SECONDARY
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|
  #|skinparam cloud {
  #|	BackgroundColor #F2FCFE-#eeeeee
  #|	BorderColor #F2FCFE
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|
  #|skinparam database {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|
  #|skinparam class {
  #|	$primary_scheme()
  #|	FontColor $FGCOLOR
  #|	HeaderBackgroundColor $PRIMARY_LIGHT
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $LIGHT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|
  #|skinparam rectangle {
  #|	$primary_scheme()
  #|	BackgroundColor $SECONDARY_LIGHT
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|
  #|skinparam package {
  #|	BackgroundColor $SECONDARY
  #|  	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|
  #|skinparam folder {
  #|	BackgroundColor $SECONDARY_LIGHT
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|
  #|skinparam frame {
  #|	BackgroundColor $SECONDARY_LIGHT
  #|  	BorderColor $INFO
  #|	FontColor $INFO
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|
  #|skinparam state {
  #|	$primary_scheme()
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|
  #|skinparam card {
  #|	BackgroundColor $INFO
  #|	BorderColor $INFO_DARK
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|
  #|skinparam file {
  #|	BackgroundColor $SECONDARY_DARK
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub

///|
// name: spacelab-white
// display_name: Spacelab White
// description: Theme based off of the bootstrap theme of the same name
// author: KingPlus-lang
// release:
// license: MIT
// version: Adapted by KingPlus-lang from `spacelab` theme of Brett Schwarz
// source: https://github.com/bschwarz/puml-themes
// inspiration: https://bootswatch.com/spacelab/
let builtin_theme_36 : String =
  #|
  #|!$THEME = "spacelab-white"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "white"
  #|!endif
  #|
  #|skinparam backgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|
  #|''
  #|'' Colors taken from the css file of the BS theme
  #|''
  #|!$BLUE = "#446e9b"
  #|!$INDIGO = "#6610f2"
  #|!$PURPLE = "#6f42c1"
  #|!$PINK = "#e83e8c"
  #|!$RED = "#cd0200"
  #|!$ORANGE = "#fd7e14"
  #|!$YELLOW = "#d47500"
  #|!$GREEN = "#3cb521"
  #|!$TEAL = "#20c997"
  #|!$CYAN = "#3399f3"
  #|!$WHITE = "#ffffff"
  #|!$GRAY = "#777777"
  #|!$GRAYDARK = "#333333"
  #|!$PRIMARY = "#446e9b"
  #|!$SECONDARY = "#999999"
  #|!$SUCCESS = "#3cb521"
  #|!$INFO = "#3399f3"
  #|!$WARNING = "#d47500"
  #|!$DANGER = "#cd0200"
  #|!$LIGHT = "#eeeeee"
  #|!$DARK = "#333333"
  #|
  #|'' *_DARK = tint (lighter) of the main color of 80%
  #|''          where TINT is calculated by clr + (255-clr) * tint_factor
  #|'' *_LIGHT = shade (darker) of the main color of 80%
  #|''          and SHADE is calculated by clr * (1 - shade_factor)
  #|''
  #|!$FGCOLOR = $WHITE
  #|!$PRIMARY_DARK = "#304d6d"
  #|!$PRIMARY_LIGHT = "#7c9ab9"
  #|!$PRIMARY_TEXT = $WHITE
  #|!$SECONDARY_DARK = "#6b6b6b"
  #|!$SECONDARY_LIGHT = "#b8b8b8"
  #|!$SECONDARY_TEXT = $WHITE
  #|!$INFO_DARK = "#246baa"
  #|!$INFO_LIGHT = "#70b8f7"
  #|!$INFO_TEXT = $WHITE
  #|!$SUCCESS_DARK = "#32a243"
  #|!$SUCCESS_LIGHT = "#4cbc5c"
  #|!$SUCCESS_TEXT = $WHITE
  #|!$WARNING_DARK = "#945200"
  #|!$WARNING_LIGHT = "#e19e4d"
  #|!$WARNING_TEXT = $WHITE
  #|!$DANGER_DARK = "#900100"
  #|!$DANGER_LIGHT = "#dc4e4d"
  #|!$DANGER_TEXT = $WHITE
  #|!$DARK_DARK = "#242424"
  #|!$DARK_LIGHT = "#707070"
  #|!$LIGHT_DARK = "#a7a7a7"
  #|!$LIGHT_LIGHT = "#f3f3f3"
  #|
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|
  #|!procedure $primary_scheme()
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY_DARK
  #|	BackgroundColor $PRIMARY_LIGHT-$PRIMARY_DARK
  #|!endprocedure
  #|''
  #|'' Style settings
  #|''
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $ORANGE
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|   Padding 15
  #|   roundcorner 20
  #|   BackgroundColor $PRIMARY-$PRIMARY_DARK
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY
  #|    FontColor $INFO
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $DARK
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|  }
  #|  nwdiagDiagram {
  #|	network {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontColor $PRIMARY_DARK
  #|	}
  #|	server {
  #|		$primary_scheme()
  #|	}
  #|	arrow {
  #|		FontColor $PRIMARY_DARK
  #|		LineColor $PRIMARY_DARK
  #|	}
  #|	group {
  #|		BackGroundColor $LIGHT
  #|		LineColor $LIGHT_DARK
  #|		LineThickness 2.0
  #|		Margin 5
  #|		Padding 5
  #|	}
  #|  }
  #|  participant {
  #|    Margin 5 40
  #|    Padding 15 20
  #|  }
  #|  ganttDiagram {
  #|	task {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		Margin 10 2 2 2
  #|		Padding 6
  #|	}
  #|	note {
  #|		FontColor $INFO_TEXT
  #|		LineColor $INFO_DARK
  #|		BackGroundColor $INFO
  #|	}
  #|	separator {
  #|		LineColor $SECONDARY
  #|		BackGroundColor $SECONDARY-$SECONDARY_DARK
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	milestone {
  #|		FontColor $INFO
  #|		FontSize 16
  #|		FontStyle italic
  #|		BackGroundColor $SECONDARY
  #|		LineColor $SECONDARY_DARK
  #|	}
  #|	timeline {
  #|		BackgroundColor $SECONDARY
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	closed {
  #|		BackgroundColor $WARNING_DARK
  #|		FontColor $WARNING_TEXT
  #|	}
  #|  }
  #|</style>
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName       "Verdana"
  #|skinparam defaultFontSize       12
  #|skinparam dpi                   100
  #|skinparam shadowing             false
  #|skinparam roundcorner           8
  #|skinparam BoxPadding            40
  #|skinparam ArrowColor            $DARK
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_LIGHT
  #|    CBorderColor $SECONDARY_DARK
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontColor	                 $PRIMARY_DARK
  #|	BorderColor	                 $SECONDARY_DARK
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor              $SECONDARY_LIGHT-$SECONDARY
  #|}
  #|
  #|skinparam legend {
  #|	BackgroundColor $SECONDARY
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $LIGHT
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $PRIMARY_DARK
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $SECONDARY_LIGHT-$SECONDARY_DARK
  #|  	DiamondBorderColor $SECONDARY_DARK
  #|  	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|
  #|skinparam sequence {
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $BGCOLOR
  #|	BoxBorderColor $DARK
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $SECONDARY
  #|	LifeLineBorderThickness 2
  #|	LifeLineBackgroundColor $SECONDARY_DARK-$SECONDARY_DARK
  #|	''
  #|	GroupBorderColor $DARK
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO
  #|	GroupBackgroundColor $SECONDARY_DARK-$SECONDARY_DARK
  #|	GroupHeaderBackgroundColor $BGCOLOR
  #|	''
  #|	DividerBackgroundColor $DARK_LIGHT-$DARK_DARK
  #|    DividerBorderColor $DARK
  #|    DividerBorderThickness 2
  #|    DividerFontColor $LIGHT
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceBorderColor $DARK
  #|	ReferenceFontColor $DARK
  #|	ReferenceHeaderFontColor $INFO
  #|	ReferenceHeaderBackgroundColor $SECONDARY_DARK-$SECONDARY_DARK
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|
  #|skinparam control {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|
  #|skinparam entity {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|
  #|skinparam boundary {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|
  #|skinparam agent {
  #|	BackgroundColor $WARNING
  #|	BorderColor $WARNING_LIGHT
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $INFO_LIGHT-$INFO_DARK
  #|	BorderColor $INFO_DARK
  #|	FontColor $WHITE
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|
  #|skinparam artifact {
  #|	BackgroundColor $DARK
  #|	BorderColor $DARK_DARK
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|
  #|skinparam component {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|
  #|skinparam interface {
  #|	BackgroundColor  $DANGER_DARK
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|
  #|skinparam storage {
  #|	BackgroundColor $WARNING
  #|  	BorderColor $WARNING_DARK
  #|	FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|
  #|skinparam node {
  #|	BackgroundColor  $SECONDARY
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|
  #|skinparam cloud {
  #|	BackgroundColor #F2FCFE-#eeeeee
  #|	BorderColor #F2FCFE
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|
  #|skinparam database {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|
  #|skinparam class {
  #|	$primary_scheme()
  #|	FontColor $WHITE
  #|	HeaderBackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|	StereotypeFontColor $LIGHT
  #|	BorderThickness 1
  #|	AttributeFontColor $LIGHT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|
  #|skinparam rectangle {
  #|	$primary_scheme()
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY_DARK
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|
  #|skinparam package {
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY_DARK
  #|  	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|
  #|skinparam folder {
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY_DARK
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|
  #|skinparam frame {
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY_DARK
  #|  	BorderColor $INFO
  #|	FontColor $INFO
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|
  #|skinparam state {
  #|	$primary_scheme()
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|
  #|skinparam card {
  #|	BackgroundColor $INFO_LIGHT-$INFO_DARK
  #|	BorderColor $INFO_DARK
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|
  #|skinparam file {
  #|	BackgroundColor $SECONDARY_DARK-$SECONDARY_DARK
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub

///|
// name: spacelab
// display_name: Spacelab
// description: Theme based off of the bootstrap theme of the same name
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration: https://bootswatch.com/spacelab/
let builtin_theme_37 : String =
  #|
  #|!$THEME = "spacelab"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "transparent"
  #|!endif
  #|
  #|skinparam backgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|
  #|''
  #|'' Colors taken from the css file of the BS theme
  #|''
  #|!$BLUE = "#446e9b"
  #|!$INDIGO = "#6610f2"
  #|!$PURPLE = "#6f42c1"
  #|!$PINK = "#e83e8c"
  #|!$RED = "#cd0200"
  #|!$ORANGE = "#fd7e14"
  #|!$YELLOW = "#d47500"
  #|!$GREEN = "#3cb521"
  #|!$TEAL = "#20c997"
  #|!$CYAN = "#3399f3"
  #|!$WHITE = "#ffffff"
  #|!$GRAY = "#777777"
  #|!$GRAYDARK = "#333333"
  #|!$PRIMARY = "#446e9b"
  #|!$SECONDARY = "#999999"
  #|!$SUCCESS = "#3cb521"
  #|!$INFO = "#3399f3"
  #|!$WARNING = "#d47500"
  #|!$DANGER = "#cd0200"
  #|!$LIGHT = "#eeeeee"
  #|!$DARK = "#333333"
  #|
  #|'' *_DARK = tint (lighter) of the main color of 80%
  #|''          where TINT is calculated by clr + (255-clr) * tint_factor
  #|'' *_LIGHT = shade (darker) of the main color of 80%
  #|''          and SHADE is calculated by clr * (1 - shade_factor)
  #|''
  #|!$FGCOLOR = $WHITE
  #|!$PRIMARY_DARK = "#304d6d"
  #|!$PRIMARY_LIGHT = "#7c9ab9"
  #|!$PRIMARY_TEXT = $WHITE
  #|!$SECONDARY_DARK = "#6b6b6b"
  #|!$SECONDARY_LIGHT = "#b8b8b8"
  #|!$SECONDARY_TEXT = $WHITE
  #|!$INFO_DARK = "#246baa"
  #|!$INFO_LIGHT = "#70b8f7"
  #|!$INFO_TEXT = $WHITE
  #|!$SUCCESS_DARK = "#32a243"
  #|!$SUCCESS_LIGHT = "#4cbc5c"
  #|!$SUCCESS_TEXT = $WHITE
  #|!$WARNING_DARK = "#945200"
  #|!$WARNING_LIGHT = "#e19e4d"
  #|!$WARNING_TEXT = $WHITE
  #|!$DANGER_DARK = "#900100"
  #|!$DANGER_LIGHT = "#dc4e4d"
  #|!$DANGER_TEXT = $WHITE
  #|!$DARK_DARK = "#242424"
  #|!$DARK_LIGHT = "#707070"
  #|!$LIGHT_DARK = "#a7a7a7"
  #|!$LIGHT_LIGHT = "#f3f3f3"
  #|
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|
  #|!procedure $primary_scheme()
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY_DARK
  #|	BackgroundColor $PRIMARY_LIGHT-$PRIMARY_DARK
  #|!endprocedure
  #|''
  #|'' Style settings
  #|''
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $ORANGE
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|   Padding 15
  #|   roundcorner 20
  #|   BackgroundColor $PRIMARY-$PRIMARY_DARK
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY
  #|    FontColor $INFO
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $DARK
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|  }
  #|  nwdiagDiagram {
  #|	network {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontColor $PRIMARY_DARK
  #|	}
  #|	server {
  #|		$primary_scheme()
  #|	}
  #|	arrow {
  #|		FontColor $PRIMARY_DARK
  #|		LineColor $PRIMARY_DARK
  #|	}
  #|	group {
  #|		BackGroundColor $LIGHT
  #|		LineColor $LIGHT_DARK
  #|		LineThickness 2.0
  #|		Margin 5
  #|		Padding 5
  #|	}
  #|  }
  #|  participant {
  #|    Margin 5 40
  #|    Padding 15 20
  #|  }
  #|  ganttDiagram {
  #|	task {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		Margin 10 2 2 2
  #|		Padding 6
  #|	}
  #|	note {
  #|		FontColor $INFO_TEXT
  #|		LineColor $INFO_DARK
  #|		BackGroundColor $INFO
  #|	}
  #|	separator {
  #|		LineColor $SECONDARY
  #|		BackGroundColor $SECONDARY-$SECONDARY_DARK
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	milestone {
  #|		FontColor $INFO
  #|		FontSize 16
  #|		FontStyle italic
  #|		BackGroundColor $SECONDARY
  #|		LineColor $SECONDARY_DARK
  #|	}
  #|	timeline {
  #|		BackgroundColor $SECONDARY
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	closed {
  #|		BackgroundColor $WARNING_DARK
  #|		FontColor $WARNING_TEXT
  #|	}
  #|  }
  #|</style>
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName       "Verdana"
  #|skinparam defaultFontSize       12
  #|skinparam dpi                   100
  #|skinparam shadowing             false
  #|skinparam roundcorner           8
  #|skinparam BoxPadding            40
  #|skinparam ArrowColor            $DARK
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_LIGHT
  #|    CBorderColor $SECONDARY_DARK
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontColor	                 $PRIMARY_DARK
  #|	BorderColor	                 $SECONDARY_DARK
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor              $SECONDARY_LIGHT-$SECONDARY
  #|}
  #|
  #|skinparam legend {
  #|	BackgroundColor $SECONDARY
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $LIGHT
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $PRIMARY_DARK
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $SECONDARY_LIGHT-$SECONDARY_DARK
  #|  	DiamondBorderColor $SECONDARY_DARK
  #|  	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|
  #|skinparam sequence {
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $BGCOLOR
  #|	BoxBorderColor $DARK
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $SECONDARY
  #|	LifeLineBorderThickness 2
  #|	LifeLineBackgroundColor $SECONDARY_DARK-$SECONDARY_DARK
  #|	''
  #|	GroupBorderColor $DARK
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO
  #|	GroupBackgroundColor $SECONDARY_DARK-$SECONDARY_DARK
  #|	GroupHeaderBackgroundColor $BGCOLOR
  #|	''
  #|	DividerBackgroundColor $DARK_LIGHT-$DARK_DARK
  #|    DividerBorderColor $DARK
  #|    DividerBorderThickness 2
  #|    DividerFontColor $LIGHT
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceBorderColor $DARK
  #|	ReferenceFontColor $DARK
  #|	ReferenceHeaderFontColor $INFO
  #|	ReferenceHeaderBackgroundColor $SECONDARY_DARK-$SECONDARY_DARK
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|
  #|skinparam control {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|
  #|skinparam entity {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|
  #|skinparam boundary {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|
  #|skinparam agent {
  #|	BackgroundColor $WARNING
  #|	BorderColor $WARNING_LIGHT
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $INFO_LIGHT-$INFO_DARK
  #|	BorderColor $INFO_DARK
  #|	FontColor $WHITE
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|
  #|skinparam artifact {
  #|	BackgroundColor $DARK
  #|	BorderColor $DARK_DARK
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|
  #|skinparam component {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|
  #|skinparam interface {
  #|	BackgroundColor  $DANGER_DARK
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|
  #|skinparam storage {
  #|	BackgroundColor $WARNING
  #|  	BorderColor $WARNING_DARK
  #|	FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|
  #|skinparam node {
  #|	BackgroundColor  $SECONDARY
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|
  #|skinparam cloud {
  #|	BackgroundColor #F2FCFE-#eeeeee
  #|	BorderColor #F2FCFE
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|
  #|skinparam database {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|
  #|skinparam class {
  #|	$primary_scheme()
  #|	FontColor $WHITE
  #|	HeaderBackgroundColor $PRIMARY_LIGHT-$PRIMARY
  #|	StereotypeFontColor $LIGHT
  #|	BorderThickness 1
  #|	AttributeFontColor $LIGHT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|
  #|skinparam rectangle {
  #|	$primary_scheme()
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY_DARK
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|
  #|skinparam package {
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY_DARK
  #|  	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|
  #|skinparam folder {
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY_DARK
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|
  #|skinparam frame {
  #|	BackgroundColor $SECONDARY_LIGHT-$SECONDARY_DARK
  #|  	BorderColor $INFO
  #|	FontColor $INFO
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|
  #|skinparam state {
  #|	$primary_scheme()
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|
  #|skinparam card {
  #|	BackgroundColor $INFO_LIGHT-$INFO_DARK
  #|	BorderColor $INFO_DARK
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|
  #|skinparam file {
  #|	BackgroundColor $SECONDARY_DARK-$SECONDARY_DARK
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub

///|
// name: sunlust
// display_name: Sunlust
// description: A theme based off of the [solarized theme](https://ethanschoonover.com/solarized)
// author: Artem V. Ageev
// release:
// license: GPL 3+
// version:
// source:
// inspiration: https://ethanschoonover.com/solarized
let builtin_theme_38 : String =
  #|
  #|!$THEME = 'sunlust'
  #|!$colors = {
  #|    "font"      : "#657b83",
  #|    "bg"        : "#fdf6e3",
  #|    "yellow"    : "#b58900",
  #|    "yellow_bg" : "#BUSINESS",
  #|    "orange"    : "#cb4b16",
  #|    "orange_bg" : "#STRATEGY",
  #|    "red"       : "#dc322f",
  #|    "red_bg"    : "#IMPLEMENTATION",
  #|    "violet"    : "#6c71c4",
  #|    "violet_bg" : "#MOTIVATION",
  #|    "blue"      : "#268bd2",
  #|    "blue_bg"   : "#APPLICATION",
  #|    "green"     : "#859900",
  #|    "green_bg"  : "#TECHNOLOGY"
  #|}
  #|!$shapes = {
  #|    "TECHNOLOGY" : {
  #|        "color" : "#859900",
  #|        "shapes" : [
  #|            "Node",
  #|            "File",
  #|            "Artifact",
  #|            "Circle"
  #|        ]
  #|    },
  #|    "APPLICATION" : {
  #|        "color" : "#268bd2",
  #|        "shapes" : [
  #|            "Participant",
  #|            "Rectangle",
  #|            "Component",
  #|            "Hexagon",
  #|            "Agent"
  #|        ]
  #|    },
  #|    "BUSINESS" : {
  #|        "color" : "#b58900",
  #|        "shapes" : [
  #|            "Actor",
  #|            "Note",
  #|            "Boundary",
  #|            "Control",
  #|            "Entity",
  #|            "Person"
  #|        ]
  #|    },
  #|    "IMPLEMENTATION" : {
  #|        "color" : "#dc322f",
  #|        "shapes" : [
  #|            "Class",
  #|            "Map",
  #|            "Json",
  #|            "Package",
  #|            "Frame",
  #|            "Interface"
  #|        ]
  #|    },
  #|    "MOTIVATION" : {
  #|        "color" : "#6c71c4",
  #|        "shapes" : [
  #|            "Cloud",
  #|            "Collections",
  #|            "Database",
  #|            "Queue",
  #|            "Process",
  #|            "Stack",
  #|            "Storage"
  #|        ]
  #|    },
  #|    "STRATEGY" : {
  #|        "color" : "#cb4b16",
  #|        "shapes" : [
  #|            "Action",
  #|            "Partition",
  #|            "Folder",
  #|            "Usecase",
  #|            "Card"
  #|        ]
  #|    }
  #|}
  #|!$thickness = 2
  #|<style>
  #|nwdiagDiagram, wbsDiagram, mindmapDiagram, ganttDiagram, saltDiagram, jsonDiagram, yamlDiagram {
  #|    BackGroundColor $colors.bg
  #|    arrow {
  #|        LineColor $colors.font
  #|        Thickness $thickness
  #|    }
  #|    node {
  #|        LineColor $colors.green
  #|        BackgroundColor $colors.green_bg
  #|    }
  #|    task {
  #|        LineColor $colors.violet
  #|        BackGroundColor $colors.violet_bg
  #|    }
  #|    milestone {
  #|        LineColor $colors.red
  #|        BackGroundColor $colors.red_bg
  #|    }
  #|}
  #|</style>
  #|
  #|skinparam noteTextAlignment left
  #|skinparam actorStyle awesome
  #|skinparam Dpi 100
  #|skinparam Shadowing false
  #|skinparam BackgroundColor $colors.bg
  #|skinparam WrapWidth 200
  #|skinparam RoundCorner 15
  #|skinparam SwimlaneBorderColor $colors.font
  #|skinparam SwimlaneThickness $thickness
  #|skinparam SwimlaneWrapTitleWidth 150
  #|skinparam ArrowColor $colors.font
  #|skinparam ArrowThickness $thickness
  #|skinparam DefaultTextAlignment center
  #|skinparam DefaultFontName Dejavu Serif
  #|skinparam LegendFontName VL Gothic
  #|skinparam LegendBorderColor transparent
  #|skinparam LegendBackgroundColor transparent
  #|skinparam SequenceMessageAlign direction
  #|skinparam SequenceArrowThickness $thickness
  #|skinparam SequenceLifeLineBorderColor $colors.yellow
  #|skinparam SequenceBoxBorderThickness $thickness
  #|!foreach $shape in %splitstr('Activity.State', '.')
  #|skinparam $shape {
  #|    BackgroundColor transparent
  #|    BorderColor  $colors.violet
  #|    BorderThickness $thickness
  #|    DiamondBorderColor $colors.red
  #|    DiamondBackgroundColor transparent
  #|}
  #|!endfor
  #|!foreach $key in %get_json_keys($shapes)
  #|    !foreach $shape in $shapes[$key].shapes
  #|skinparam $shape {
  #|    BackgroundColor #$key
  #|    BorderColor $shapes[$key].color
  #|    BorderThickness $thickness
  #|}
  #|    !endfor
  #|!endfor

///|
// name: superhero-outline
// display_name: Superhero Outline
// description: Theme based off of the bootstrap theme of the same name, with outline colors
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration: https://bootswatch.com/superhero/
let builtin_theme_39 : String =
  #|
  #|!$THEME = "superhero-outline"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "transparent"
  #|!endif
  #|
  #|skinparam backgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|
  #|''
  #|'' Colors taken from the css file of the BS theme
  #|''
  #|!$BLUE = "#DF691A"
  #|!$INDIGO = "#6610f2"
  #|!$PURPLE = "#6f42c1"
  #|!$PINK = "#e83e8c"
  #|!$RED = "#d9534f"
  #|!$ORANGE = "#f0ad4e"
  #|!$YELLOW = "#f0ad4e"
  #|!$GREEN = "#5cb85c"
  #|!$TEAL = "#20c997"
  #|!$CYAN = "#5bc0de"
  #|!$WHITE = "#FFF"
  #|!$GRAY_LIGHT = "#222"
  #|!$GRAY = "#868e96"
  #|!$PRIMARY = "#DF691A"
  #|!$SECONDARY = "#4E5D6C"
  #|!$SUCCESS = "#5cb85c"
  #|!$INFO = "#5bc0de"
  #|!$WARNING = "#f0ad4e"
  #|!$DANGER = "#d9534f"
  #|!$LIGHT = "#abb6c2"
  #|!$DARK = "#4E5D6C"
  #|
  #|'' *_DARK = tint (lighter) of the main color of 80%
  #|''          where TINT is calculated by clr + (255-clr) * tint_factor
  #|'' *_LIGHT = shade (darker) of the main color of 80%
  #|''          and SHADE is calculated by clr * (1 - shade_factor)
  #|''
  #|!$FGCOLOR = $WHITE
  #|!$PRIMARY_DARK = "#e58748"
  #|!$PRIMARY_LIGHT = "#b25415"
  #|!$PRIMARY_TEXT = $PRIMARY
  #|!$SECONDARY_DARK = "#717d89"
  #|!$SECONDARY_LIGHT = "#3e4a56"
  #|!$SECONDARY_TEXT = $SECONDARY_DARK
  #|!$INFO_DARK = "#7ccde5"
  #|!$INFO_LIGHT = "#499AB2"
  #|!$INFO_TEXT = $INFO
  #|!$SUCCESS_DARK = "#4a934a"
  #|!$SUCCESS_LIGHT = "#5F8F00"
  #|!$SUCCESS_TEXT = $SUCCESS
  #|!$WARNING_DARK = "#f3bd71"
  #|!$WARNING_LIGHT = "#C08A3E"
  #|!$WARNING_TEXT = $WARNING
  #|!$DANGER_DARK = "#e17572"
  #|!$DANGER_LIGHT = "#AE423F"
  #|!$DANGER_TEXT = $WHITE
  #|!$DARK_DARK = "#717d89"
  #|!$DARK_LIGHT = "#3e4a56"
  #|!$LIGHT_DARK = "#bcc5ce"
  #|!$LIGHT_LIGHT = "#89929b"
  #|
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|
  #|!procedure $primary_scheme()
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY_DARK
  #|	BackgroundColor $BGCOLOR
  #|!endprocedure
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $ORANGE
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|   Padding 15
  #|   roundcorner 20
  #|   BackgroundColor $BGCOLOR
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY
  #|    FontColor $INFO
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $DARK
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $BGCOLOR
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|  }
  #|  nwdiagDiagram {
  #|	network {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontColor $PRIMARY_LIGHT
  #|	}
  #|	server {
  #|		$primary_scheme()
  #|	}
  #|	arrow {
  #|		FontColor $PRIMARY_LIGHT
  #|		LineColor $PRIMARY_LIGHT
  #|	}
  #|	group {
  #|		BackGroundColor $LIGHT
  #|		LineColor $LIGHT_DARK
  #|		LineThickness 2.0
  #|		Margin 5
  #|		Padding 5
  #|	}
  #|  }
  #|  participant {
  #|    Margin 5 40
  #|    Padding 15 20
  #|  }
  #|  ganttDiagram {
  #|	task {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		Margin 10 2 2 2
  #|		Padding 6
  #|	}
  #|	note {
  #|		FontColor $INFO_TEXT
  #|		LineColor $INFO_DARK
  #|		BackGroundColor $BGCOLOR
  #|	}
  #|	separator {
  #|		LineColor $SECONDARY_DARK
  #|		BackGroundColor $BGCOLOR
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	milestone {
  #|		FontColor $INFO
  #|		FontSize 16
  #|		FontStyle italic
  #|		BackGroundColor $SECONDARY
  #|		LineColor $SECONDARY_DARK
  #|	}
  #|	timeline {
  #|		BackgroundColor $SECONDARY
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	closed {
  #|		BackgroundColor $WARNING_DARK
  #|		FontColor $WARNING_TEXT
  #|	}
  #|  }
  #|</style>
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName       "Verdana"
  #|skinparam defaultFontSize       12
  #|skinparam dpi                   100
  #|skinparam shadowing             false
  #|skinparam roundcorner           8
  #|skinparam BoxPadding            40
  #|skinparam TitleFontColor	    $DARK
  #|skinparam TitleFontSize	    	20
  #|skinparam TitleBorderThickness 	0
  #|skinparam ArrowColor            $DARK
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_DARK
  #|    CBorderColor $SECONDARY_LIGHT
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontColor	                 $PRIMARY
  #|	BorderColor	                 $SECONDARY_DARK
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor              $BGCOLOR
  #|}
  #|
  #|
  #|skinparam legend {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $LIGHT
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $BGCOLOR
  #|  	DiamondBorderColor $SECONDARY_DARK
  #|  	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	$primary_scheme()
  #|	FontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|
  #|skinparam sequence {
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $BGCOLOR
  #|	BoxBorderColor $DARK
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $SECONDARY
  #|	LifeLineBorderThickness 2
  #|	LifeLineBackgroundColor $BGCOLOR
  #|	''
  #|	GroupBorderColor $DARK
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO
  #|	GroupBackgroundColor $BGCOLOR
  #|	GroupHeaderBackgroundColor $BGCOLOR
  #|	''
  #|	DividerBackgroundColor $BGCOLOR
  #|    DividerBorderColor $DARK
  #|    DividerBorderThickness 2
  #|    DividerFontColor $LIGHT
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceBorderColor $LIGHT
  #|	ReferenceFontColor $LIGHT
  #|	ReferenceHeaderFontColor $INFO
  #|	ReferenceHeaderBackgroundColor $BGCOLOR
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|
  #|skinparam control {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|
  #|skinparam entity {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|
  #|skinparam boundary {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|
  #|skinparam agent {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $WARNING_LIGHT
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $INFO_DARK
  #|	FontColor $INFO_DARK
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|
  #|skinparam artifact {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $DARK_DARK
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|
  #|skinparam component {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|
  #|skinparam interface {
  #|	BackgroundColor  $BGCOLOR
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|
  #|skinparam storage {
  #|	BackgroundColor $BGCOLOR
  #|  	BorderColor $WARNING_DARK
  #|	FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|
  #|skinparam node {
  #|	BackgroundColor  $BGCOLOR
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|
  #|skinparam cloud {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor #F2FCFE
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|
  #|skinparam database {
  #|	$primary_scheme()
  #|	FontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|
  #|skinparam class {
  #|	$primary_scheme()
  #|	FontColor $LIGHT
  #|	HeaderBackgroundColor $PRIMARY_LIGHT
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $DARK
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $SECONDARY_DARK
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|
  #|skinparam rectangle {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|
  #|skinparam package {
  #|	BackgroundColor $BGCOLOR
  #|  	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|
  #|skinparam folder {
  #|	BackgroundColor $BGCOLOR
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|
  #|skinparam frame {
  #|	BackgroundColor $BGCOLOR
  #|  	BorderColor $INFO
  #|	FontColor $INFO
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|
  #|skinparam state {
  #|	$primary_scheme()
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|
  #|skinparam card {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $INFO
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|
  #|skinparam file {
  #|	BackgroundColor $BGCOLOR
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub

///|
// name: superhero
// display_name: Superhero
// description: Theme based off of the bootstrap theme of the same name
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration: https://bootswatch.com/superhero/
let builtin_theme_40 : String =
  #|
  #|!$THEME = "superhero"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "transparent"
  #|!endif
  #|
  #|skinparam backgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|
  #|''
  #|'' Colors taken from the css file of the BS theme
  #|''
  #|!$BLUE = "#DF691A"
  #|!$INDIGO = "#6610f2"
  #|!$PURPLE = "#6f42c1"
  #|!$PINK = "#e83e8c"
  #|!$RED = "#d9534f"
  #|!$ORANGE = "#f0ad4e"
  #|!$YELLOW = "#f0ad4e"
  #|!$GREEN = "#5cb85c"
  #|!$TEAL = "#20c997"
  #|!$CYAN = "#5bc0de"
  #|!$WHITE = "#FFF"
  #|!$GRAY_LIGHT = "#222"
  #|!$GRAY = "#868e96"
  #|!$PRIMARY = "#DF691A"
  #|!$SECONDARY = "#4E5D6C"
  #|!$SUCCESS = "#5cb85c"
  #|!$INFO = "#5bc0de"
  #|!$WARNING = "#f0ad4e"
  #|!$DANGER = "#d9534f"
  #|!$LIGHT = "#abb6c2"
  #|!$DARK = "#4E5D6C"
  #|
  #|'' *_DARK = tint (lighter) of the main color of 80%
  #|''          where TINT is calculated by clr + (255-clr) * tint_factor
  #|'' *_LIGHT = shade (darker) of the main color of 80%
  #|''          and SHADE is calculated by clr * (1 - shade_factor)
  #|''
  #|!$FGCOLOR = $WHITE
  #|!$PRIMARY_DARK = "#e58748"
  #|!$PRIMARY_LIGHT = "#b25415"
  #|!$PRIMARY_TEXT = $WHITE
  #|!$SECONDARY_DARK = "#717d89"
  #|!$SECONDARY_LIGHT = "#3e4a56"
  #|!$SECONDARY_TEXT = $WHITE
  #|!$INFO_DARK = "#7ccde5"
  #|!$INFO_LIGHT = "#499AB2"
  #|!$INFO_TEXT = $WHITE
  #|!$SUCCESS_DARK = "#4a934a"
  #|!$SUCCESS_LIGHT = "#5F8F00"
  #|!$SUCCESS_TEXT = $WHITE
  #|!$WARNING_DARK = "#f3bd71"
  #|!$WARNING_LIGHT = "#C08A3E"
  #|!$WARNING_TEXT = $WHITE
  #|!$DANGER_DARK = "#e17572"
  #|!$DANGER_LIGHT = "#AE423F"
  #|!$DANGER_TEXT = $WHITE
  #|!$DARK_DARK = "#717d89"
  #|!$DARK_LIGHT = "#3e4a56"
  #|!$LIGHT_DARK = "#bcc5ce"
  #|!$LIGHT_LIGHT = "#89929b"
  #|
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|
  #|!procedure $primary_scheme()
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY_DARK
  #|	BackgroundColor $PRIMARY
  #|!endprocedure
  #|''
  #|'' Style settings
  #|''
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $ORANGE
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|   Padding 15
  #|   roundcorner 20
  #|   BackgroundColor $PRIMARY-$PRIMARY_DARK
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY
  #|    FontColor $INFO
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $DARK
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|  }
  #|  nwdiagDiagram {
  #|	network {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontColor $PRIMARY_LIGHT
  #|	}
  #|	server {
  #|		$primary_scheme()
  #|	}
  #|	arrow {
  #|		FontColor $PRIMARY_LIGHT
  #|		LineColor $PRIMARY_LIGHT
  #|	}
  #|	group {
  #|		BackGroundColor $LIGHT
  #|		LineColor $LIGHT_DARK
  #|		LineThickness 2.0
  #|		Margin 5
  #|		Padding 5
  #|	}
  #|  }
  #|  participant {
  #|    Margin 5 40
  #|    Padding 15 20
  #|  }
  #|  ganttDiagram {
  #|	task {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		Margin 10 2 2 2
  #|		Padding 6
  #|	}
  #|	note {
  #|		FontColor $INFO_TEXT
  #|		LineColor $INFO_DARK
  #|		BackGroundColor $INFO
  #|	}
  #|	separator {
  #|		LineColor $SECONDARY
  #|		BackGroundColor $SECONDARY-$SECONDARY_DARK
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	milestone {
  #|		FontColor $INFO
  #|		FontSize 16
  #|		FontStyle italic
  #|		BackGroundColor $SECONDARY
  #|		LineColor $SECONDARY_DARK
  #|	}
  #|	timeline {
  #|		BackgroundColor $SECONDARY
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	closed {
  #|		BackgroundColor $WARNING_DARK
  #|		FontColor $WARNING_TEXT
  #|	}
  #|  }
  #|</style>
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName       "Verdana"
  #|skinparam defaultFontSize       12
  #|skinparam dpi                   100
  #|skinparam shadowing             false
  #|skinparam roundcorner           8
  #|skinparam BoxPadding            40
  #|skinparam ArrowColor            $DARK
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_LIGHT
  #|    CBorderColor $SECONDARY_DARK
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontColor	                 $PRIMARY
  #|	BorderColor	                 $SECONDARY_DARK
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor              $SECONDARY_LIGHT-$SECONDARY
  #|}
  #|
  #|skinparam legend {
  #|	BackgroundColor $SECONDARY
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $LIGHT
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $SECONDARY_LIGHT
  #|  	DiamondBorderColor $SECONDARY_DARK
  #|  	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|
  #|skinparam participant {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|
  #|skinparam sequence {
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $BGCOLOR
  #|	BoxBorderColor $DARK
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $SECONDARY
  #|	LifeLineBorderThickness 2
  #|	LifeLineBackgroundColor $SECONDARY_DARK
  #|	''
  #|	GroupBackgroundColor $SECONDARY
  #|	GroupBorderColor $DARK
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO
  #|	GroupHeaderBackgroundColor $BGCOLOR
  #|	''
  #|	DividerBackgroundColor $DARK
  #|    DividerBorderColor $DARK
  #|    DividerBorderThickness 2
  #|    DividerFontColor $LIGHT
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceBorderColor $DARK
  #|	ReferenceFontColor $DARK
  #|	ReferenceHeaderFontColor $INFO
  #|	ReferenceHeaderBackgroundColor $SECONDARY
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|
  #|skinparam control {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|
  #|skinparam entity {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|
  #|skinparam boundary {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|
  #|skinparam agent {
  #|	BackgroundColor $WARNING
  #|	BorderColor $WARNING_LIGHT
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $INFO
  #|	BorderColor $INFO_DARK
  #|	FontColor $WHITE
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|
  #|skinparam artifact {
  #|	BackgroundColor $DARK
  #|	BorderColor $DARK_DARK
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|
  #|skinparam component {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|
  #|skinparam interface {
  #|	BackgroundColor  $DANGER_DARK
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|
  #|skinparam storage {
  #|	BackgroundColor $WARNING
  #|  	BorderColor $WARNING_DARK
  #|	FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|
  #|skinparam node {
  #|	BackgroundColor  $SECONDARY
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|
  #|skinparam cloud {
  #|	BackgroundColor $LIGHT-black
  #|	BorderColor $LIGHT
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|
  #|skinparam database {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|
  #|skinparam class {
  #|	$primary_scheme()
  #|	HeaderBackgroundColor $PRIMARY_LIGHT
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $DARK
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|
  #|skinparam rectangle {
  #|	$primary_scheme()
  #|	BackgroundColor $SECONDARY_LIGHT
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|
  #|skinparam package {
  #|	BackgroundColor $SECONDARY
  #|  	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|
  #|skinparam folder {
  #|	BackgroundColor $SECONDARY_LIGHT
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|
  #|skinparam frame {
  #|	BackgroundColor $SECONDARY_LIGHT
  #|  	BorderColor $INFO
  #|	FontColor $INFO
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|
  #|skinparam state {
  #|	$primary_scheme()
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|
  #|skinparam card {
  #|	BackgroundColor $INFO
  #|	BorderColor $INFO_DARK
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|
  #|skinparam file {
  #|	BackgroundColor $SECONDARY_DARK
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub

///|
// name: toy
// display_name: Toy
// description: The toy theme from future-architect/puml-themes
// author: [future-architect](https://github.com/future-architect)
// release:
// license: Apache License, Version 2.0
// version:
// source: https://github.com/future-architect/puml-themes/tree/master/themes
// inspiration:
let builtin_theme_41 : String =
  #|
  #|skinparam BackgroundColor DDDDDD
  #|skinparam shadowing false
  #|skinparam RoundCorner 7
  #|skinparam ArrowColor 454645
  #|skinparam FontColor 454645
  #|skinparam SequenceLifeLineBorderColor 454645
  #|skinparam SequenceGroupHeaderFontColor 454645
  #|skinparam SequenceGroupFontColor 454645
  #|skinparam SequenceGroupBorderColor 454645
  #|skinparam SequenceGroupBorderThickness 1
  #|
  #|skinparam sequenceDivider {
  #|    BorderColor 454645
  #|    BorderThickness 1
  #|    FontColor 454645
  #|}
  #|
  #|skinparam participant {
  #|    BackgroundColor FF6F61
  #|    BorderColor 454645
  #|    FontColor White
  #|    BorderThickness 1.5
  #|}
  #|
  #|skinparam database {
  #|    BackgroundColor 98DDDE
  #|    BorderColor 454645
  #|    FontColor 454645
  #|}
  #|
  #|skinparam entity {
  #|    BackgroundColor FFDA29
  #|    BorderColor 454645
  #|    FontColor 454645
  #|}
  #|
  #|skinparam note {
  #|    BackgroundColor LightGreen
  #|    BorderColor 454645
  #|    FontColor 454645
  #|    BorderThickness 1
  #|}
  #|
  #|skinparam actor {
  #|    BackgroundColor 454645
  #|    BorderColor 454645
  #|    FontColor 454645
  #|}
  #|
  #|skinparam boundary {
  #|    BackgroundColor FFDA29
  #|    BorderColor 454645
  #|    FontColor 454645
  #|}
  #|
  #|skinparam control {
  #|    BackgroundColor FFDA29
  #|    BorderColor 454645
  #|    FontColor 454645
  #|}
  #|
  #|skinparam collections {
  #|    BackgroundColor FF6F61
  #|    BorderColor 454645
  #|    FontColor 454645
  #|    BorderThickness 1.5
  #|}
  #|
  #|skinparam queue {
  #|    BackgroundColor FF6F61
  #|    BorderColor 454645
  #|    FontColor FFF
  #|    BorderThickness 1.5
  #|}

///|
// name: united
// display_name: United
// description: Theme based off of the bootstrap theme of the same name
// author: Brett Schwarz
// release:
// license: MIT
// version:
// source: https://github.com/bschwarz/puml-themes
// inspiration: https://bootswatch.com/united/
let builtin_theme_42 : String =
  #|
  #|!$THEME = "united"
  #|
  #|!if %not(%variable_exists("$BGCOLOR"))
  #|!$BGCOLOR = "transparent"
  #|!endif
  #|
  #|skinparam backgroundColor $BGCOLOR
  #|skinparam useBetaStyle false
  #|
  #|''
  #|'' Colors taken from the css file of the BS theme
  #|''
  #|!$BLUE = "#007bff"
  #|!$INDIGO = "#6610f2"
  #|!$PURPLE = "#772953"
  #|!$PINK = "#e83e8c"
  #|!$RED = "#df382c"
  #|!$ORANGE = "#e95420"
  #|!$YELLOW = "#efb73e"
  #|!$GREEN = "#38b44a"
  #|!$TEAL = "#20c997"
  #|!$CYAN = "#17a2b8"
  #|!$WHITE = "#fff"
  #|!$GRAY = "#868e96"
  #|!$GRAYDARK = "#333"
  #|!$PRIMARY = "#e95420"
  #|!$SECONDARY = "#aea79f"
  #|!$SUCCESS = "#38b44a"
  #|!$INFO = "#17a2b8"
  #|!$WARNING = "#efb73e"
  #|!$DANGER = "#df382c"
  #|!$LIGHT = "#e9ecef"
  #|!$DARK = "#772953"
  #|
  #|'' *_DARK = tint (lighter) of the main color of 80%
  #|''          where TINT is calculated by clr + (255-clr) * tint_factor
  #|'' *_LIGHT = shade (darker) of the main color of 80%
  #|''          and SHADE is calculated by clr * (1 - shade_factor)
  #|''
  #|!$FGCOLOR = $WHITE
  #|!$PRIMARY_DARK = "#d24c1d"
  #|!$PRIMARY_LIGHT = "#eb6536"
  #|!$PRIMARY_TEXT = $WHITE
  #|!$SECONDARY_DARK = "#9d968f"
  #|!$SECONDARY_LIGHT = "#b6b0a9"
  #|!$SECONDARY_TEXT = $WHITE
  #|!$INFO_DARK = "#1592a6"
  #|!$INFO_LIGHT = "#2eabbf"
  #|!$INFO_TEXT = $WHITE
  #|!$SUCCESS_DARK = "#32a243"
  #|!$SUCCESS_LIGHT = "#4cbc5c"
  #|!$SUCCESS_TEXT = $WHITE
  #|!$WARNING_DARK = "#d7a538"
  #|!$WARNING_LIGHT = "#f1be51"
  #|!$WARNING_TEXT = $WHITE
  #|!$DANGER_DARK = "#c93228"
  #|!$DANGER_LIGHT = "#e24c41"
  #|!$DANGER_TEXT = $WHITE
  #|!$DARK_DARK = "#6b254b"
  #|!$DARK_LIGHT = "#853e64"
  #|!$LIGHT_DARK = "#d2d4d7"
  #|!$LIGHT_LIGHT = "#ebeef1"
  #|
  #|!procedure $success($msg)
  #|  <font color=$SUCCESS><b>$msg
  #|!endprocedure
  #|
  #|!procedure $failure($msg)
  #|  <font color=$DANGER><b>$msg
  #|!endprocedure
  #|
  #|!procedure $warning($msg)
  #|  <font color=$WARNING><b>$msg
  #|!endprocedure
  #|
  #|!procedure $primary_scheme()
  #|	FontColor $PRIMARY_TEXT
  #|	BorderColor $PRIMARY_DARK
  #|	BackgroundColor $PRIMARY
  #|!endprocedure
  #|''
  #|'' Style settings
  #|''
  #|<style>
  #|  root {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $PRIMARY_TEXT
  #|    HyperLinkColor $ORANGE
  #|    LineColor $PRIMARY_DARK
  #|    LineThickness 1
  #|    Margin 10
  #|    Padding 6
  #|    Shadowing 0.0
  #|  }
  #|  node {
  #|   Padding 15
  #|   roundcorner 20
  #|   BackgroundColor $PRIMARY-$PRIMARY_DARK
  #|  }
  #|  caption {
  #|    LineThickness 0
  #|  }
  #|  footer {
  #|    LineThickness 0
  #|  }
  #|  groupHeader {
  #|    BackgroundColor $SECONDARY
  #|    FontColor $INFO
  #|    FontStyle bold
  #|  }
  #|  header {
  #|    LineThickness 0
  #|  }
  #|  referenceHeader {
  #|    BackgroundColor $BGCOLOR
  #|    FontColor $DARK
  #|    FontStyle bold
  #|  }
  #|  separator {
  #|    BackgroundColor $FGCOLOR
  #|    FontColor $BGCOLOR
  #|    FontStyle bold
  #|  }
  #|  title {
  #|	FontSize 20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	FontColor $PRIMARY
  #|	BorderColor $SECONDARY
  #|  }
  #|  nwdiagDiagram {
  #|	network {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		LineThickness 1.0
  #|		FontColor $PRIMARY_DARK
  #|	}
  #|	server {
  #|		$primary_scheme()
  #|	}
  #|	arrow {
  #|		FontColor $PRIMARY_DARK
  #|		LineColor $PRIMARY_DARK
  #|	}
  #|	group {
  #|		BackGroundColor $LIGHT
  #|		LineColor $LIGHT_DARK
  #|		LineThickness 2.0
  #|		Margin 5
  #|		Padding 5
  #|	}
  #|  }
  #|  participant {
  #|    Margin 5 40
  #|    Padding 15 20
  #|  }
  #|  ganttDiagram {
  #|	task {
  #|		$primary_scheme()
  #|		LineColor $PRIMARY
  #|		Margin 10 2 2 2
  #|		Padding 6
  #|	}
  #|	note {
  #|		FontColor $INFO_TEXT
  #|		LineColor $INFO_DARK
  #|		BackGroundColor $INFO
  #|	}
  #|	separator {
  #|		LineColor $SECONDARY
  #|		BackGroundColor $SECONDARY-$SECONDARY_DARK
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	milestone {
  #|		FontColor $INFO
  #|		FontSize 16
  #|		FontStyle italic
  #|		BackGroundColor $SECONDARY
  #|		LineColor $SECONDARY_DARK
  #|	}
  #|	timeline {
  #|		BackgroundColor $SECONDARY
  #|		FontColor $SECONDARY_TEXT
  #|	}
  #|	closed {
  #|		BackgroundColor $WARNING_DARK
  #|		FontColor $WARNING_TEXT
  #|	}
  #|  }
  #|</style>
  #|''
  #|'' Global Default Values
  #|''
  #|skinparam defaultFontName       "Verdana"
  #|skinparam defaultFontSize       12
  #|skinparam dpi                   100
  #|skinparam shadowing             false
  #|skinparam roundcorner           8
  #|skinparam BoxPadding            40
  #|skinparam ArrowColor            $DARK
  #|skinparam stereotype {
  #|    CBackgroundColor $SECONDARY_LIGHT
  #|    CBorderColor $SECONDARY_DARK
  #|    ABackgroundColor $SUCCESS_LIGHT
  #|    ABorderColor $SUCCESS_DARK
  #|    IBackgroundColor $DANGER_LIGHT
  #|    IBorderColor $DANGER_DARK
  #|    EBackgroundColor $WARNING_LIGHT
  #|    EBorderColor $WARNING_DARK
  #|    NBackgroundColor $INFO_LIGHT
  #|    NBorderColor $INFO_DARK
  #|}
  #|skinparam title {
  #|	FontColor	                 $PRIMARY
  #|	BorderColor	                 $SECONDARY_DARK
  #|	FontSize	    	         20
  #|	BorderRoundCorner            8
  #|	BorderThickness 	         1
  #|	BackgroundColor              $SECONDARY_LIGHT-$SECONDARY
  #|}
  #|
  #|skinparam legend {
  #|	BackgroundColor $SECONDARY
  #|	BorderColor $SECONDARY_DARK
  #|	FontColor $LIGHT
  #|}
  #|
  #|!startsub swimlane
  #|skinparam swimlane {
  #|	BorderColor $INFO
  #|	BorderThickness 2
  #|	TitleBackgroundColor  $SECONDARY_LIGHT-$SECONDARY
  #|	TitleFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub activity
  #|
  #|skinparam activity {
  #|	$primary_scheme()
  #|	BarColor $SUCCESS
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	''
  #|	DiamondBackgroundColor $SECONDARY_LIGHT
  #|  	DiamondBorderColor $SECONDARY_DARK
  #|  	DiamondFontColor $SECONDARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub participant
  #|
  #|skinparam participant {
  #|	$primary_scheme()
  #|	ParticipantBorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub actor
  #|
  #|skinparam actor {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub arrow
  #|
  #|skinparam arrow {
  #|	Thickness 3
  #|	Color $PRIMARY
  #|	FontColor $FGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub sequence
  #|
  #|skinparam sequence {
  #|	BorderColor $PRIMARY
  #|	' For some reason sequence title font color does not pick up from global
  #|	TitleFontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|	StartColor $PRIMARY
  #|	EndColor $PRIMARY
  #|	''
  #|	BoxBackgroundColor $BGCOLOR
  #|	BoxBorderColor $DARK
  #|	BoxFontColor $DARK
  #|	''
  #|	DelayFontColor $DARK
  #|	''
  #|	LifeLineBorderColor $SECONDARY
  #|	LifeLineBorderThickness 2
  #|	LifeLineBackgroundColor $SECONDARY_DARK
  #|	''
  #|	GroupBorderColor $DARK
  #|	GroupFontColor $DARK
  #|	GroupHeaderFontColor $INFO
  #|	GroupBackgroundColor $SECONDARY
  #|	GroupHeaderBackgroundColor $BGCOLOR
  #|	''
  #|	DividerBackgroundColor $DARK
  #|    DividerBorderColor $DARK
  #|    DividerBorderThickness 2
  #|    DividerFontColor $LIGHT
  #|	''
  #|	ReferenceBackgroundColor $BGCOLOR
  #|	ReferenceBorderColor $DARK
  #|	ReferenceFontColor $DARK
  #|	ReferenceHeaderFontColor $INFO
  #|	ReferenceHeaderBackgroundColor $SECONDARY
  #|	''
  #|	StereotypeFontColor $PRIMARY_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub partition
  #|
  #|skinparam partition {
  #|	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BackgroundColor $BGCOLOR
  #|}
  #|!endsub
  #|
  #|!startsub collections
  #|
  #|skinparam collections {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub control
  #|
  #|skinparam control {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub entity
  #|
  #|skinparam entity {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub boundary
  #|
  #|skinparam boundary {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub agent
  #|
  #|skinparam agent {
  #|	BackgroundColor $WARNING
  #|	BorderColor $WARNING_LIGHT
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub note
  #|
  #|skinparam note {
  #|	BorderThickness 1
  #|	BackgroundColor $INFO
  #|	BorderColor $INFO_DARK
  #|	FontColor $WHITE
  #|}
  #|!endsub
  #|
  #|!startsub artifact
  #|
  #|skinparam artifact {
  #|	BackgroundColor $DARK
  #|	BorderColor $DARK_DARK
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub component
  #|
  #|skinparam component {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub interface
  #|
  #|skinparam interface {
  #|	BackgroundColor  $DANGER_DARK
  #|	BorderColor  $DANGER
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub storage
  #|
  #|skinparam storage {
  #|	BackgroundColor $WARNING
  #|  	BorderColor $WARNING_DARK
  #|	FontColor $WARNING_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub node
  #|
  #|skinparam node {
  #|	BackgroundColor  $SECONDARY
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub cloud
  #|
  #|skinparam cloud {
  #|	BackgroundColor #F2FCFE-#eeeeee
  #|	BorderColor #F2FCFE
  #|	FontColor $DARK
  #|}
  #|!endsub
  #|
  #|!startsub database
  #|
  #|skinparam database {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub class
  #|
  #|skinparam class {
  #|	$primary_scheme()
  #|	HeaderBackgroundColor $PRIMARY_LIGHT
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $DARK
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub object
  #|
  #|skinparam object {
  #|	$primary_scheme()
  #|	StereotypeFontColor $DARK
  #|	BorderThickness 1
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub usecase
  #|
  #|skinparam usecase {
  #|	$primary_scheme()
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub rectangle
  #|
  #|skinparam rectangle {
  #|	$primary_scheme()
  #|	BackgroundColor $SECONDARY_LIGHT
  #|	BorderThickness 2
  #|	StereotypeFontColor $PRIMARY
  #|}
  #|!endsub
  #|
  #|!startsub package
  #|
  #|skinparam package {
  #|	BackgroundColor $SECONDARY
  #|  	BorderColor $PRIMARY
  #|	FontColor $PRIMARY
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub folder
  #|
  #|skinparam folder {
  #|	BackgroundColor $SECONDARY_LIGHT
  #|  	BorderColor $WARNING
  #|	FontColor $WARNING
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub frame
  #|
  #|skinparam frame {
  #|	BackgroundColor $SECONDARY_LIGHT
  #|  	BorderColor $INFO
  #|	FontColor $INFO
  #|	BorderThickness 2
  #|}
  #|!endsub
  #|
  #|!startsub state
  #|
  #|skinparam state {
  #|	$primary_scheme()
  #|	BackgroundColor $PRIMARY_LIGHT
  #|	StartColor $INFO
  #|	EndColor $INFO
  #|	AttributeFontColor $SECONDARY_TEXT
  #|	AttributeFontSize 11
  #|}
  #|!endsub
  #|
  #|!startsub queue
  #|
  #|skinparam queue {
  #|	$primary_scheme()
  #|}
  #|!endsub
  #|
  #|!startsub card
  #|
  #|skinparam card {
  #|	BackgroundColor $INFO
  #|	BorderColor $INFO_DARK
  #|	FontColor $INFO_TEXT
  #|}
  #|!endsub
  #|
  #|!startsub file
  #|
  #|skinparam file {
  #|	BackgroundColor $SECONDARY_DARK
  #|	BorderColor $LIGHT
  #|	FontColor $LIGHT
  #|}
  #|!endsub
  #|
  #|!startsub stack
  #|
  #|skinparam stack {
  #|	$primary_scheme()
  #|}
  #|!endsub

///|
// name: vibrant
// display_name: Vibrant
// description: The vibrant theme from https://github.com/future-architect/puml-themes
// author: [future-architect](https://github.com/future-architect)
// release:
// license: Apache License, Version 2.0
// version:
// source: https://github.com/future-architect/puml-themes/tree/master/themes
// inspiration:
let builtin_theme_43 : String =
  #|
  #|skinparam BackgroundColor FFFFFF
  #|skinparam shadowing false
  #|skinparam RoundCorner 7
  #|skinparam ArrowColor 454645
  #|skinparam FontColor 454645
  #|skinparam SequenceLifeLineBorderColor 696969
  #|skinparam SequenceGroupHeaderFontColor 454645
  #|skinparam SequenceGroupFontColor 696969
  #|skinparam SequenceGroupBorderColor 696969
  #|skinparam SequenceGroupBorderThickness 1
  #|
  #|skinparam sequenceDivider {
  #|    BorderColor 454645
  #|    BorderThickness 1
  #|    FontColor 454645
  #|}
  #|
  #|skinparam participant {
  #|    BackgroundColor FF6347
  #|    BorderColor 454645
  #|    FontColor FFFFFF
  #|    BorderThickness 1.5
  #|}
  #|
  #|skinparam database {
  #|    BackgroundColor 00FFFF
  #|    BorderColor 454645
  #|    FontColor 454645
  #|}
  #|
  #|skinparam entity {
  #|    BackgroundColor FFE552
  #|    BorderColor 454645
  #|    FontColor 454645
  #|}
  #|
  #|skinparam note {
  #|    BackgroundColor 7FFFD4
  #|    BorderColor 454645
  #|    FontColor 454645
  #|    BorderThickness 1.5
  #|}
  #|
  #|skinparam actor {
  #|    BackgroundColor 454645
  #|    BorderColor 454645
  #|    FontColor 454645
  #|}
  #|
  #|skinparam boundary {
  #|    BackgroundColor FFE552
  #|    BorderColor 454645
  #|    FontColor 454645
  #|}
  #|
  #|skinparam control {
  #|    BackgroundColor FFE552
  #|    BorderColor 454645
  #|    FontColor 454645
  #|}
  #|
  #|skinparam collections {
  #|    BackgroundColor FF5F42
  #|    BorderColor 454645
  #|    FontColor 454645
  #|}
  #|
  #|skinparam queue {
  #|    BackgroundColor FF6347
  #|    BorderColor 454645
  #|    FontColor FFF
  #|    BorderThickness 1.5
  #|}
