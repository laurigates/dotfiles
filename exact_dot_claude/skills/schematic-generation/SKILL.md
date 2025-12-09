---
name: schematic-generation
description: |
  Generate color-coded electronics schematic diagrams from wiring documentation using AI image generation.
  Parses WIRING.md or similar documentation files, researches component pinouts via web search,
  and generates visual schematic images with hobby-friendly color coding using Nano Banana Pro.

  Use when the user wants to:
  - Generate a schematic from wiring documentation
  - Visualize circuit connections from a WIRING.md file
  - Create circuit diagrams for embedded projects
  - Generate hardware documentation images

  Triggers: "generate schematic", "create schematic", "schematic from wiring",
  "visualize circuit", "circuit diagram", "wiring diagram image"
---

# Schematic Generation from Wiring Documentation

Generate professional, color-coded electronics schematic diagrams from text-based wiring documentation. This skill combines web research for accurate component pinouts with AI image generation using a hobby-friendly color scheme.

## Requirements

### Dependencies
- nano-banana-pro skill (Gemini 3 Pro Image)
- `GOOGLE_API_KEY` or `GEMINI_API_KEY` environment variable

### Installation
```bash
pip install google-genai Pillow
```

## Color Scheme for Hobby Electronics

Use this standardized color scheme to make schematics easy to follow. These colors match common conventions in electronics (multimeter probes, jumper wire sets, Fritzing).

### Power Rails (Universal Convention)

| Element | Color | Hex Code | Rationale |
|---------|-------|----------|-----------|
| **Positive voltage** (VCC, 3.3V, 5V, 12V) | **RED** | #FF0000 | Matches red multimeter probe, red jumper wires |
| **Ground** (GND) | **BLACK** | #000000 | Matches black multimeter probe, black jumper wires |
| **Negative voltage** (if used) | **BLUE** | #0000FF | Convention for negative rails |

### Signal Types by Color

| Signal Type | Color | Hex Code | Examples |
|-------------|-------|----------|----------|
| **SPI bus** | **ORANGE** | #FF8C00 | MOSI, MISO, SCK, CS/SS |
| **I2C bus** | **BLUE** | #0066CC | SDA, SCL |
| **UART** | **PURPLE** | #9932CC | TX, RX |
| **Digital inputs** | **GREEN** | #228B22 | Buttons, switches, sensors |
| **Digital outputs** | **YELLOW** | #FFD700 | LEDs, relays, control signals |
| **PWM signals** | **CYAN** | #00CED1 | Motors, buzzers, dimmers |
| **Analog signals** | **PINK** | #FF69B4 | ADC inputs, DAC outputs |
| **Interrupt lines** | **MAGENTA** | #FF00FF | IRQ, INT pins |

### Component Background Highlights

| Component Type | Background | Hex Code | Purpose |
|----------------|------------|----------|---------|
| **Microcontroller** | Light blue | #E6F3FF | Central focus of diagram |
| **Input devices** | Light green | #E6FFE6 | Buttons, switches, sensors |
| **Output devices** | Light yellow | #FFFDE6 | LEDs, motors, displays |
| **Communication modules** | Light orange | #FFF0E6 | RFID, WiFi, Bluetooth |
| **Power components** | Light gray | #F0F0F0 | Regulators, batteries |

### Warning and Safety Indicators

| Indicator | Style | Use Case |
|-----------|-------|----------|
| **Voltage warning** | Amber box with text | "3.3V ONLY - NOT 5V TOLERANT" |
| **Polarity critical** | Red triangle | Capacitors, diodes, ICs |
| **Heat warning** | Orange outline | Regulators, power transistors |
| **ESD sensitive** | Yellow lightning symbol | MOSFETs, ICs |

### Visual Hierarchy

| Element | Line Weight | Purpose |
|---------|-------------|---------|
| **Power rails** | Thick (3px) | Most important, easy to trace |
| **Signal wires** | Medium (2px) | Standard connections |
| **Reference lines** | Thin (1px) | Annotations, boundaries |
| **Connection dots** | Filled circles | Show wire junctions clearly |

## Workflow

### Step 1: Parse Wiring Documentation

Read the wiring documentation file (typically `WIRING.md`) to extract:

- **Central microcontroller** (e.g., ESP32, Arduino, STM32)
- **Connected components** with their GPIO assignments
- **Communication protocols** (SPI, I2C, UART)
- **Power connections** (3.3V, 5V, GND)
- **Special circuits** (transistor drivers, voltage dividers)

### Step 2: Research Component Pinouts (IMPORTANT)

**Before generating the schematic, search for pinout diagrams of each component.**

For each component identified in the wiring documentation:

```
Search: "[COMPONENT NAME] pinout diagram"
Search: "[MICROCONTROLLER MODEL] GPIO pinout"
```

**Example searches:**
- "WEMOS Battery ESP32 pinout"
- "WEMOS D1 Mini ESP32 pinout diagram"
- "RC522 RFID module pinout"
- "SW-200D tilt switch pinout"
- "2N2222 NPN transistor pinout"

**Extract from search results:**
- Pin names and numbers
- Pin functions (VCC, GND, SDA, SCL, etc.)
- Operating voltage (3.3V vs 5V)
- Physical pin layout (if relevant)

**Verify against wiring documentation:**
- Confirm GPIO assignments match component capabilities
- Check for any pin conflicts
- Validate communication protocol pins (SPI, I2C)

### Step 3: Build Color-Coded Schematic Prompt

Incorporate the color scheme into the prompt:

```
Color-coded electronics schematic diagram of [DEVICE TYPE] circuit.
Hobby-friendly visual style with clear color coding for easy wire tracing.

COLOR SCHEME:
- RED wires and rails for positive power (3.3V, 5V, VCC)
- BLACK wires and rails for ground (GND)
- ORANGE wires for SPI bus (MOSI, MISO, SCK, CS)
- BLUE wires for I2C bus (SDA, SCL)
- GREEN wires for digital inputs (buttons, switches)
- YELLOW wires for digital outputs (LEDs, control)
- CYAN wires for PWM signals (motors, buzzers)

COMPONENT HIGHLIGHTING:
- Microcontroller with light blue background (central focus)
- Input devices with light green background
- Output devices with light yellow background
- Communication modules with light orange background

[MICROCONTROLLER AND COMPONENT DETAILS...]

VISUAL STYLE:
- Thick red and black lines for power rails at top and bottom
- Medium colored lines for signal connections
- Filled dots at wire junctions to show connections
- Clear component labels with GPIO numbers
- Warning boxes in amber for voltage-sensitive components
- Legend/key showing wire color meanings
- White background with clean layout
- Professional but approachable hobby style
```

### Step 4: Generate Image

```bash
python ~/.claude/scripts/nano_banana_pro.py \
  "[COLOR-CODED PROMPT]" \
  --aspect 16:9 \
  --resolution 2K \
  --output schematic.png
```

## Complete Example: ESP32 Audiobook Player (Color-Coded)

### Color-Coded Prompt Template

```
Color-coded electronics schematic diagram of an ESP32-based RFID audiobook player.
Hobby-friendly visual style optimized for makers and beginners.

=== COLOR SCHEME (ALWAYS INCLUDE IN LEGEND) ===
Wire colors following standard conventions:
- RED (#FF0000): Positive power rails (3.3V) - thick lines
- BLACK (#000000): Ground rails (GND) - thick lines
- ORANGE (#FF8C00): SPI bus signals (MOSI, MISO, SCK, CS)
- GREEN (#228B22): Digital inputs (buttons, tilt switch)
- YELLOW (#FFD700): Digital outputs (status LED)
- CYAN (#00CED1): PWM outputs (buzzer, motor control)

=== LAYOUT ===
- RED 3.3V power rail running horizontally across TOP of diagram
- BLACK GND rail running horizontally across BOTTOM of diagram
- Components arranged in logical groups between rails
- Signal flow generally left-to-right

=== MICROCONTROLLER (Light blue background box) ===
WEMOS D1 Mini ESP32 in center showing labeled pins:
- 3.3V pin connected to RED top rail
- GND pin connected to BLACK bottom rail
- GPIO17: ORANGE wire to RC522 SDA/CS
- GPIO18: ORANGE wire to RC522 SCK
- GPIO19: ORANGE wire to RC522 MISO
- GPIO23: ORANGE wire to RC522 MOSI
- GPIO25: CYAN wire to piezo buzzer
- GPIO26: CYAN wire to transistor base
- GPIO27: GREEN wire to tilt switch
- GPIO32: GREEN wire to play button
- GPIO33: GREEN wire to pause button
- GPIO16: YELLOW wire to status LED

=== RC522 RFID MODULE (Light orange background box) ===
8-pin module on LEFT side:
- VCC: RED wire to 3.3V rail
- GND: BLACK wire to GND rail
- RST: RED wire to 3.3V (held high)
- IRQ: Not connected (NC label)
- SDA: ORANGE wire to GPIO17
- SCK: ORANGE wire to GPIO18
- MOSI: ORANGE wire to GPIO23
- MISO: ORANGE wire to GPIO19
- AMBER WARNING BOX: "3.3V ONLY - NOT 5V TOLERANT"

=== INPUT DEVICES (Light green background box) ===
Upper LEFT area:
- Green push button labeled "PLAY": GREEN wire to GPIO32, BLACK wire to GND
- Red push button labeled "PAUSE": GREEN wire to GPIO33, BLACK wire to GND
- SW-200D tilt switch: GREEN wire to GPIO27, BLACK wire to GND
- Note: "Internal pull-ups enabled"

=== OUTPUT DEVICES (Light yellow background box) ===
RIGHT side:
- Passive piezo buzzer: CYAN wire (+) to GPIO25, BLACK wire (-) to GND
- Status LED with 330Ω resistor: YELLOW wire to GPIO16, BLACK wire to GND

=== MOTOR DRIVER CIRCUIT (Light yellow background box) ===
Lower RIGHT:
- 2N2222 NPN transistor (show EBC pinout diagram)
- 1kΩ resistor: CYAN wire from GPIO26 to Base
- Collector: to motor negative terminal
- Emitter: BLACK wire to GND rail
- Coin vibration motor: RED wire (+) from 3.3V, wire (-) to Collector
- 1N4148 flyback diode across motor (cathode to RED/3.3V)

=== LEGEND BOX (Bottom right corner) ===
Wire Color Key:
🔴 RED = Power (3.3V)
⚫ BLACK = Ground (GND)
🟠 ORANGE = SPI Bus
🟢 GREEN = Digital Input
🟡 YELLOW = Digital Output
🔵 CYAN = PWM Signal

=== VISUAL STYLE ===
- Clean white background
- Thick power rails (RED top, BLACK bottom)
- Colored wires matching legend
- Filled black dots at all wire junctions
- Component outlines in dark gray
- Background highlight boxes for component groups
- All text labels in black, high contrast
- GPIO numbers clearly visible on MCU
- Pin names on all module connections
- Professional hobby electronics style (like Fritzing but cleaner)
```

## Prompt Enhancement Function (Updated)

```python
def build_colored_schematic_prompt(
    components: dict,
    pinout_research: dict
) -> str:
    """Build color-coded schematic prompt with researched pinout data."""

    # Color scheme constants
    COLORS = {
        'power': 'RED (#FF0000)',
        'ground': 'BLACK (#000000)',
        'spi': 'ORANGE (#FF8C00)',
        'i2c': 'BLUE (#0066CC)',
        'uart': 'PURPLE (#9932CC)',
        'digital_in': 'GREEN (#228B22)',
        'digital_out': 'YELLOW (#FFD700)',
        'pwm': 'CYAN (#00CED1)',
        'analog': 'PINK (#FF69B4)',
    }

    BACKGROUNDS = {
        'mcu': 'light blue',
        'input': 'light green',
        'output': 'light yellow',
        'communication': 'light orange',
        'power': 'light gray',
    }

    header = f"""Color-coded electronics schematic diagram of {components['device_type']}.
Hobby-friendly visual style optimized for makers and beginners.

=== COLOR SCHEME (INCLUDE LEGEND) ===
- {COLORS['power']}: Positive power rails - thick lines
- {COLORS['ground']}: Ground rails - thick lines
- {COLORS['spi']}: SPI bus signals (MOSI, MISO, SCK, CS)
- {COLORS['i2c']}: I2C bus signals (SDA, SCL)
- {COLORS['digital_in']}: Digital inputs (buttons, switches)
- {COLORS['digital_out']}: Digital outputs (LEDs)
- {COLORS['pwm']}: PWM signals (motors, buzzers)
"""

    layout = """
=== LAYOUT ===
- RED power rail at TOP of diagram
- BLACK ground rail at BOTTOM of diagram
- Components in logical groups between rails
- Signal flow left-to-right
"""

    # Build component sections with colors
    sections = []

    # MCU section
    mcu = components['microcontroller']
    mcu_pins = pinout_research.get(mcu, {})
    mcu_section = f"""
=== MICROCONTROLLER ({BACKGROUNDS['mcu']} background) ===
{mcu} in center with labeled pins:"""

    for gpio, info in mcu_pins.items():
        signal_type = info.get('type', 'digital_out')
        color = COLORS.get(signal_type, COLORS['digital_out'])
        mcu_section += f"\n- {gpio}: {color} wire to {info['destination']}"

    sections.append(mcu_section)

    # Add peripheral sections with appropriate colors
    for comp in components.get('peripherals', []):
        comp_type = comp.get('type', 'output')
        bg = BACKGROUNDS.get(comp_type, 'light gray')
        section = f"\n=== {comp['name'].upper()} ({bg} background) ===\n"
        section += comp.get('description', '')
        sections.append(section)

    style = """
=== VISUAL STYLE ===
- Clean white background
- Thick power rails (RED top, BLACK bottom)
- Colored wires matching legend
- Filled black dots at wire junctions
- Component outlines in dark gray
- Background boxes for component groups
- High contrast black text labels
- GPIO numbers clearly visible
- Professional hobby style
"""

    legend = """
=== LEGEND BOX (Corner) ===
Wire Color Key with colored squares
"""

    return header + layout + "\n".join(sections) + style + legend
```

## Web Search Patterns

### Microcontrollers
```
"[BOARD NAME] pinout diagram"
"[BOARD NAME] GPIO reference"
"[BOARD NAME] schematic"
```

### Modules (RFID, Sensors, Displays)
```
"[MODULE NAME] pinout"
"[MODULE NAME] wiring diagram"
"[MODULE NAME] datasheet pinout"
```

### Discrete Components
```
"[PART NUMBER] pinout"
"[PART NUMBER] datasheet"
"[COMPONENT TYPE] [PACKAGE] pinout"
```

### Communication Protocols
```
"ESP32 SPI pins VSPI HSPI"
"ESP32 I2C default pins"
"[MCU] hardware UART pins"
```

## Best Practices

### Color Usage

1. **Be consistent** - Same signal type = same color throughout
2. **Include legend** - Always add a color key to the diagram
3. **Consider colorblind users** - Use patterns/labels in addition to colors
4. **Don't overuse** - Stick to the defined palette, avoid random colors
5. **Power first** - Always use red/black for power rails (universal convention)

### Research Phase

1. **Always verify voltage levels** - 3.3V vs 5V components
2. **Confirm protocol pins** - Default SPI/I2C pins vary by MCU
3. **Check strapping pins** - ESP32 GPIO0, 2, 5, 12, 15 affect boot
4. **Note power requirements** - Current draw for motors, LEDs
5. **Find physical pinouts** - TO-92, DIP, module layouts

### Prompt Construction

1. **Specify colors explicitly** - Include hex codes for precision
2. **Describe layout** - Power rails top/bottom, signal flow direction
3. **Group components** - Use background colors for visual organization
4. **Add warnings** - Voltage limits, polarity, heat
5. **Include legend** - Essential for understanding the diagram

### Aspect Ratios

| Circuit Complexity | Recommended |
|-------------------|-------------|
| Simple (< 5 components) | 4:3 |
| Medium (5-10 components) | 16:9 |
| Complex (> 10 components) | 21:9 |

## Accessibility Considerations

For colorblind-friendly schematics, add these elements:

1. **Text labels** on all wires (not just colors)
2. **Line patterns** - Dashed for one type, dotted for another
3. **Symbols** at endpoints - Different shapes for different signals
4. **High contrast** - Ensure colors differ in brightness, not just hue
5. **Legend with both** - Color swatches AND text descriptions

## Limitations

**AI-generated schematics may have:**
- Incorrect component symbol shapes
- Overlapping or misaligned connections
- Color inconsistencies
- Duplicate components
- Non-standard notation

**For production documentation:**
Use proper EDA tools like KiCad, Eagle, or Fritzing. AI-generated schematics are best suited for:
- Quick visualization during development
- Documentation drafts
- Conceptual diagrams
- README illustrations
- Teaching and learning

## Related Skills

- **nano-banana-pro**: Base image generation capability
- **embedded-systems**: ESP32/STM32 development expertise
- **kicad**: Professional schematic capture (MCP tools available)

## References

- [Wiring Color Codes - All About Circuits](https://www.allaboutcircuits.com/textbook/reference/chpt-2/wiring-color-codes/)
- [Fritzing Graphic Standards](https://fritzing.org/fritzings-graphic-standards/)
- [Rules for Drawing Good Schematics - EE Stack Exchange](https://electronics.stackexchange.com/questions/28251/rules-and-guidelines-for-drawing-good-schematics)
