pub(crate) type Method = u32;

pub(crate) type Layout = u32;

pub(crate) const NVIQ_IME_MASK_LAYOUT: u32 = 0x0000FFFF;

pub(crate) const NVIQ_IME_LAYOUT_NONE: Layout = 0x00000000;
pub(crate) const NVIQ_IME_LAYOUT_US: Layout = 0x00000409;
pub(crate) const NVIQ_IME_LAYOUT_CHINESE_SIMPLIFIED: Layout = 0x0000804;
pub(crate) const NVIQ_IME_LAYOUT_CHINESE_TRADITIONAL: Layout = 0x00000404;
pub(crate) const NVIQ_IME_LAYOUT_JAPANESE: Layout = 0x00000411;
pub(crate) const NVIQ_IME_LAYOUT_KOREAN: Layout = 0x00000412;

pub(crate) type Source = u32;

pub(crate) const NVIQ_IME_MASK_SOURCE: u32 = 0xFFFF0000;

pub(crate) const NVIQ_IME_SOURCE_NONE: Source = 0x00000000;
pub(crate) const NVIQ_IME_SOURCE_PINYIN: Source = 0x00000000;
pub(crate) const NVIQ_IME_SOURCE_WUBI: Source = 0x00010000;
