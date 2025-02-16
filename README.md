Reasoned for a second
Závěrečná zpráva (vhodné vysvětlení pro studenty)

Název: Pochopení konverze HAR → HEF pro YOLOv11 pomocí Hailo Dataflow Compileru
1. Úvod
Máte YOLOv11 model (neurální síť pro detekci objektů), který chcete provozovat na Hailo hardwaru. K tomu musíte nejprve model převést na HAR soubor (meziformát Hailo), a poté se Hailo Dataflow Compiler pokouší vyrobit soubor HEF (konečný „program“ pro Hailo čip). Tato zpráva shrnuje, co se během této konverze děje – především opakované „iterace“ (kroky) zobrazené v protokolech (logech) kompilátoru.

2. Co jsou HAR a HEF
HAR („Hailo Archive“)
Můžete si ho představit jako mezikrok. Už máte natrénovaný model, vyexportujete jej do ONNX (například) a spustíte překlad. Ten pak vytvoří HAR, který je „téměř připraven“, ale je potřeba jej optimalizovat pro Hailo čip.

HEF („Hailo Executable File“)
Toto je výsledek, který se skutečně načte do Hailo hardwaru. Jakmile máte .hef, můžete na Hailo zařízení spouštět inference (vyhodnocování modelu).

3. Co nám ukazuje výpis z kompilátoru
Při spuštění:

css
Copy
Edit
hailo_dataflow_compiler --input my_model.har --output my_model.hef
(případně obdobného příkazu v Pythonu) kompilátor provádí následující:

Pokus o Single-Context

Kompilátor se nejprve pokusí umístit celý YOLO model do čipu jako jeden velký „blok“ (single context). To může přinést lepší výkon, ale často narazí na omezení zdrojů.
V logu uvidíte např.:
vbnet
Copy
Edit
Model fits in single context ...
Trying to apply higher utilization solution ...
...
Single context flow failed ...
To znamená, že to zkusil, ale model použil příliš mnoho „layer controllers“ nebo paměti. Nakonec single context opustí.
Pokus o Multi-Context

Protože single context se nepodařilo, kompilátor model rozdělí do dvou nebo tří kontextů. Každý kontext je jako další „část programu“ na čipu.
Kompilátor tak opakovaně zkouší různé uspořádání (tzv. „iterace“), kde nastavuje, jak se vrstvy modelu sdružují či dělí. Některé iterace selžou („Too many LCUs“, „Splitter timeout“), jiné najdou částečné řešení a zvýší „Fast FPS“.
Iterace #1, #2, #3 ...

Každá iterace je jeden pokus interního „solveru“ (řešiče) o nové mapování.
Selhání mohou být:
Splitter timeout: v daném kroku strávil řešič příliš času hledáním proveditelného uspořádání.
Too many LCUs: čip má jen 128 „layer controllers“, ale model potřebuje třeba 130 či 142.
Validator failed: někde nevyhovuje rozměr konvoluce pravidlům paměťového zarovnání.
Co se stane nakonec

Kompilátor buď najde validní rozdělení a vytvoří .hef, nebo (pokud se to nepodaří) selže úplně.
Pozor: Tyto iterace nejsou trénovací epochy. Jde o kompilační kroky, jak fyzicky umístit „tensory“ (data neuronové sítě) do pamětí a výpočetních bloků v čipu.

4. Co jsou tensory a proč se optimalizují
Tensory:
V deep learningu je „tensor“ vícerozměrné pole (např. 2D obraz či 4D batch obrazů). Každá vrstva v YOLO zpracovává určité pole (Height × Width × Channels).

Optimalizace v Hailo:
Čip má striktní hardwarové meze na počty kanálů či „layer controllers“ atd. Kompilátor se snaží těmito tensory „šoupat“ tak, aby se vešly.

U velkého modelu je často nezbytné jej rozdělit do víc kontextů, aby nepřekročil kapacitu jediné části čipu.
5. Shrnutí Logu
Single Context:

Log ukazuje „Model fits in single context“, ale pak se snaží „increase utilization“ (zvýšit využití a výkon). Nakonec to narazí na limit (např. 129 > 128).
Nezdaří se, takže to přejde na multi-context.
Multi-Context:

Vidíte „Iteration #1 ... Iteration #114“ i více. Každá iterace zkouší jiné rozložení vrstev a pamětí. Některé kódy hlásí „Splitter timeout“, jiné „Too many lcus (130 > 128)“.
Někdy stoupá „Fast FPS“ (odhad snímků za vteřinu). Kompilátor hledá nejrychlejší proveditelnou variantu.
6. Výsledky a doporučení
Zda se kompilátor podaří

Pokud nakonec uvidíte „Compile completed successfully“ a vznikne .hef, znamená to, že se rozdělení povedlo.
Pokud končí chybou a .hef nevznikne, je model příliš velký či jinak nevyhovuje.
Chcete-li rychlejší či snazší kompatibilitu

Zvažte menší variantu YOLO (např. YOLOv5n nebo YOLOv8n) či ořez (pruning).
Případně si nastudujte doporučení Hailo k velikosti jader, zarovnání atd.
7. Závěrem (pro 17letého studenta)
Představte si, že čip je „garáž“ s určitým počtem parkovacích míst.
Model YOLO jsou „auta“, která tam chcete zaparkovat.
„Single context“ je snaha nacpat všechna auta do jedné velké sekce. „Multi-context“ je rozdělit auta do více oddělených sekcí.
Výpis (log) ukazuje, jak se kompilátor snaží auta různě přeskupovat, někdy selže (auta se nevejdou, špatná velikost kol v určité části). Nakonec (snad) najde funkční uspořádání. To je váš .hef.
Tak hodně štěstí s používáním Hailo compileru a nasazováním YOLO modelu na reálný hardware. Pochopení těchto logů vám ukáže, že nejde o trénování, ale o fyzické umístění neuronové sítě na čip, abyste mohli v reálném čase detekovat objekty.
