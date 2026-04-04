import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'HyperIsland',
  description: '为澎湃 OS3 打造的超级岛通知增强模块',

  head: [
    ['link', { rel: 'icon', type: 'image/png', href: 'https://github.com/user-attachments/assets/dc034ec0-90cf-4371-9ab0-132ca2527b32' }]
  ],

  // /en/ 路径重写到 en/ 目录下的英文文件
  rewrites: {
    'en/getting-started.md': 'en/getting-started.md',
    'en/features.md': 'en/features.md',
    'en/build.md': 'en/build.md',
    'en/contribute.md': 'en/contribute.md',
    'en/index.md': 'en/index.md'
  },

  locales: {
    root: {
      label: '简体中文',
      lang: 'zh-CN',
      themeConfig: {
        nav: nav('zh'),
        sidebar: sidebar('zh'),
        editLink: {
          pattern: 'https://github.com/1812z/HyperIsland/edit/main/docs/:path',
          text: '在 GitHub 上编辑此页面'
        }
      }
    },
    en: {
      label: 'English',
      lang: 'en-US',
      themeConfig: {
        nav: nav('en'),
        sidebar: sidebar('en'),
        editLink: {
          pattern: 'https://github.com/1812z/HyperIsland/edit/main/docs/en/:path',
          text: 'Edit this page on GitHub'
        }
      }
    }
  },

  themeConfig: {
    logo: 'https://github.com/user-attachments/assets/dc034ec0-90cf-4371-9ab0-132ca2527b32',
    socialLinks: [
      { icon: 'github', link: 'https://github.com/1812z/HyperIsland' }
    ],
    footer: {
      message: '基于 MIT 许可证发布',
      copyright: '© 2024-present 1812z'
    }
  }
})

function nav(lang: string) {
  if (lang === 'zh') {
    return [
      { text: '快速上手', link: '/getting-started', activeMatch: '/getting-started' },
      { text: '功能介绍', link: '/features', activeMatch: '/features' },
      {
        text: '更多',
        items: [
          { text: '构建指南', link: '/build' },
          { text: '贡献指南', link: '/contribute' }
        ]
      }
    ]
  }
  return [
    { text: 'Quick Start', link: '/en/getting-started', activeMatch: '/en/getting-started' },
    { text: 'Features', link: '/en/features', activeMatch: '/en/features' },
    {
      text: 'More',
      items: [
        { text: 'Build Guide', link: '/en/build' },
        { text: 'Contributing', link: '/en/contribute' }
      ]
    }
  ]
}

function sidebar(lang: string) {
  if (lang === 'zh') {
    return [
      {
        text: '开始使用',
        items: [
          { text: '快速上手', link: '/getting-started' },
          { text: '功能介绍', link: '/features' }
        ]
      },
      {
        text: '深入了解',
        items: [
          { text: '构建指南', link: '/build' },
          { text: '贡献指南', link: '/contribute' }
        ]
      }
    ]
  }
  return [
    {
      text: 'Getting Started',
      items: [
        { text: 'Quick Start', link: '/en/getting-started' },
        { text: 'Features', link: '/en/features' }
      ]
    },
    {
      text: 'Deep Dive',
      items: [
        { text: 'Build Guide', link: '/en/build' },
        { text: 'Contributing', link: '/en/contribute' }
      ]
    }
  ]
}
