import React, { useState, useEffect, useRef, useMemo } from 'react';
import { createClient } from '@supabase/supabase-js';
import { z } from 'zod';
import {
  BookOpen,
  Calendar as CalendarIcon,
  CheckCircle2,
  Clock,
  Plus,
  Search,
  Settings as SettingsIcon,
  Home,
  User,
  TrendingUp,
  AlertTriangle,
  Sparkles,
  Image as ImageIcon,
  RotateCcw,
  Trash2,
  Edit3,
  X,
  Upload,
  Check,
  Smartphone,
  Tablet,
  Monitor,
  Download,
  Share2,
  Sliders,
  Database,
  History,
  Lock,
  Mail,
  ShieldCheck,
  LogOut,
  CaretLeft,
  CaretRight
} from 'lucide-react';

// ==========================================
// 1. SUPABASE CLIENT & ZOD SCHEMAS
// ==========================================
// Замените на ваши реальные ключи Supabase при подключении
const SUPABASE_URL = 'https://your-project.supabase.co';
const SUPABASE_ANON_KEY = 'your-anon-key';
export const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

export const authSchema = z.object({
  email: z.string().email('Введите корректный email'),
  password: z.string().min(6, 'Пароль должен быть не менее 6 символов'),
});

export const studentSchema = z.object({
  id: z.string().optional(),
  name: z.string().min(2, 'Имя должно содержать минимум 2 символа'),
  language: z.enum(['English', 'Arabic']),
  totalLessons: z.number().min(1),
  completedLessons: z.number().default(0),
  startDate: z.string(),
  endDate: z.string(),
  price: z.number().min(0),
  duration: z.number().default(60),
  color: z.string().default('#ec4899'), // Цвет ученика для календаря
  notes: z.string().optional(),
  history: z.array(z.any()).optional(),
});

export type Student = z.infer<typeof studentSchema>;

export interface Lesson {
  id: string;
  studentId: string;
  date: string; // YYYY-MM-DD
  time: string; // HH:mm
  topic: string;
  completed: boolean;
}

// ==========================================
// 2. THEMES & DESIGN SYSTEM PRESETS
// ==========================================
const THEMES = [
  {
    id: 'spring',
    name: 'Spring Blossom',
    category: 'Сезонные',
    bgGradient: 'linear-gradient(135deg, #fbc2eb 0%, #a6c1ee 100%)',
    glassBg: 'rgba(255, 255, 255, 0.45)',
    glassBorder: 'rgba(255, 255, 255, 0.6)',
    primary: '#ec4899',
    text: '#1f2937',
    cardBg: 'rgba(255, 255, 255, 0.55)',
    icon: '🌸'
  },
  {
    id: 'midnight',
    name: 'Midnight Glass',
    category: 'Минимализм',
    bgGradient: 'linear-gradient(135deg, #0f172a 0%, #1e1b4b 100%)',
    glassBg: 'rgba(30, 41, 59, 0.65)',
    glassBorder: 'rgba(255, 255, 255, 0.12)',
    primary: '#38bdf8',
    text: '#f8fafc',
    cardBg: 'rgba(15, 23, 42, 0.6)',
    icon: '🌙'
  },
  {
    id: 'autumn',
    name: 'Autumn Amber',
    category: 'Сезонные',
    bgGradient: 'linear-gradient(135deg, #451a03 0%, #78350f 50%, #b45309 100%)',
    glassBg: 'rgba(120, 53, 15, 0.45)',
    glassBorder: 'rgba(251, 191, 36, 0.3)',
    primary: '#f59e0b',
    text: '#fef3c7',
    cardBg: 'rgba(69, 26, 3, 0.55)',
    icon: '🍂'
  },
  {
    id: 'winter',
    name: 'Winter Frost',
    category: 'Сезонные',
    bgGradient: 'linear-gradient(135deg, #e0f2fe 0%, #bae6fd 50%, #7dd3fc 100%)',
    glassBg: 'rgba(255, 255, 255, 0.6)',
    glassBorder: 'rgba(255, 255, 255, 0.8)',
    primary: '#0284c7',
    text: '#0f172a',
    cardBg: 'rgba(255, 255, 255, 0.7)',
    icon: '❄️'
  },
  {
    id: 'gold_luxury',
    name: 'Графитово-золотая',
    category: 'Премиум',
    bgGradient: 'linear-gradient(135deg, #18181b 0%, #27272a 50%, #09090b 100%)',
    glassBg: 'rgba(39, 39, 42, 0.65)',
    glassBorder: 'rgba(234, 179, 8, 0.4)',
    primary: '#eab308',
    text: '#fafafa',
    cardBg: 'rgba(24, 24, 27, 0.75)',
    icon: '👑'
  }
];

const INITIAL_STUDENTS: Student[] = [
  {
    id: '1',
    name: 'Алина Захарова',
    language: 'English',
    totalLessons: 10,
    completedLessons: 8,
    startDate: '2026-10-12',
    endDate: '2026-11-12',
    price: 15000,
    duration: 60,
    color: '#ec4899',
    notes: 'Интермедиат уровень. Подготовка к собеседованию.',
    history: [
      { id: 'h1', date: '2026-10-14 11:00', note: 'Разбор Грамматики Present Perfect' }
    ]
  },
  {
    id: '2',
    name: 'Мухаммад Аль-Мансур',
    language: 'Arabic',
    totalLessons: 10,
    completedLessons: 5,
    startDate: '2026-10-01',
    endDate: '2026-11-01',
    price: 18000,
    duration: 90,
    color: '#38bdf8',
    notes: 'Диалект Египта + Письменность',
    history: []
  }
];

// ==========================================
// 3. MAIN APP COMPONENT
// ==========================================
export default function App() {
  const [session, setSession] = useState<any>(null);
  const [authLoading, setAuthLoading] = useState(true);

  // App state
  const [students, setStudents] = useState<Student[]>(() => {
    const saved = localStorage.getItem('dashulya_students');
    return saved ? JSON.parse(saved) : INITIAL_STUDENTS;
  });

  const [lessons, setLessons] = useState<Lesson[]>(() => {
    const saved = localStorage.getItem('dashulya_lessons');
    return saved ? JSON.parse(saved) : [
      { id: 'l1', studentId: '1', date: new Date().toISOString().slice(0, 10), time: '11:00', topic: 'Present Perfect', completed: false }
    ];
  });

  const [activeThemeId, setActiveThemeId] = useState(() => localStorage.getItem('dashulya_theme') || 'spring');
  const [customBg, setCustomBg] = useState(() => localStorage.getItem('dashulya_custom_bg') || null);
  const [bgBlur, setBgBlur] = useState(() => Number(localStorage.getItem('dashulya_bg_blur')) || 16);
  const [bgDim, setBgDim] = useState(() => Number(localStorage.getItem('dashulya_bg_dim')) || 10);
  const [borderRadius, setBorderRadius] = useState(() => Number(localStorage.getItem('dashulya_radius')) || 24);
  const [deviceMode, setDeviceMode] = useState(() => localStorage.getItem('dashulya_device') || 'auto');
  const [animationsEnabled, setAnimationsEnabled] = useState(() => localStorage.getItem('dashulya_anim') !== 'false');

  const [activeTab, setActiveTab] = useState('main'); // 'main' | 'calendar' | 'settings'

  // Modals state
  const [isStudentModalOpen, setIsStudentModalOpen] = useState(false);
  const [editingStudent, setEditingStudent] = useState<Student | null>(null);
  const [lessonModalStudent, setLessonModalStudent] = useState<Student | null>(null);
  const [historyStudent, setHistoryStudent] = useState<Student | null>(null);
  const [isPwaModalOpen, setIsPwaModalOpen] = useState(false);
  
  // Calendar modal state
  const [calendarModalDate, setCalendarModalDate] = useState<string | null>(null);

  // Filters state
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState('all');

  // Supabase Auth Listener
  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setAuthLoading(false);
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
      setAuthLoading(false);
    });

    return () => subscription.unsubscribe();
  }, []);

  // Save to localStorage
  useEffect(() => { localStorage.setItem('dashulya_students', JSON.stringify(students)); }, [students]);
  useEffect(() => { localStorage.setItem('dashulya_lessons', JSON.stringify(lessons)); }, [lessons]);
  useEffect(() => { localStorage.setItem('dashulya_theme', activeThemeId); }, [activeThemeId]);

  const currentTheme = useMemo(() => {
    return THEMES.find((t) => t.id === activeThemeId) || THEMES[0];
  }, [activeThemeId]);

  if (authLoading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-slate-950 text-slate-100">
        <div className="animate-pulse text-sm">Загрузка приложения...</div>
      </div>
    );
  }

  // Если пользователь не вошел — показываем экран авторизации
  if (!session) {
    return <AuthScreen />;
  }

  const handleConfirmLesson = (studentId: string, date: string, note: string) => {
    setStudents((prev) =>
      prev.map((s) => {
        if (s.id === studentId) {
          const completed = Math.min(s.totalLessons, s.completedLessons + 1);
          const newHistory = [
            { id: Date.now().toString(), date, note: note || 'Занятие проведено' },
            ...(s.history || [])
          ];
          return { ...s, completedLessons: completed, history: newHistory };
        }
        return s;
      })
    );
    setLessonModalStudent(null);
  };

  const handleSaveStudent = (formData: any) => {
    if (editingStudent) {
      setStudents((prev) => prev.map((s) => (s.id === editingStudent.id ? { ...s, ...formData } : s)));
    } else {
      const newStudent = { id: Date.now().toString(), ...formData, completedLessons: 0, history: [] };
      setStudents((prev) => [newStudent, ...prev]);
    }
    setIsStudentModalOpen(false);
    setEditingStudent(null);
  };

  const handleDeleteStudent = (id: string) => {
    if (window.confirm('Удалить этого ученика?')) {
      setStudents((prev) => prev.filter((s) => s.id !== id));
      if (historyStudent?.id === id) setHistoryStudent(null);
    }
  };

  const handleAddLessonFromCalendar = (lessonData: Omit<Lesson, 'id' | 'completed'>) => {
    const newLesson: Lesson = {
      id: Date.now().toString(),
      ...lessonData,
      completed: false,
    };
    setLessons((prev) => [...prev, newLesson]);
  };

  const filteredStudents = useMemo(() => {
    return students.filter((s) => {
      const matchesSearch = s.name.toLowerCase().includes(searchQuery.toLowerCase()) || (s.notes && s.notes.toLowerCase().includes(searchQuery.toLowerCase()));
      if (!matchesSearch) return false;
      const remaining = s.totalLessons - s.completedLessons;
      const isExpired = new Date(s.endDate) < new Date();

      if (statusFilter === 'active') return remaining > 0 && !isExpired;
      if (statusFilter === 'ending') return remaining > 0 && remaining <= 2;
      if (statusFilter === 'expired') return isExpired || remaining === 0;
      if (statusFilter === 'english') return s.language === 'English';
      if (statusFilter === 'arabic') return s.language === 'Arabic';
      return true;
    });
  }, [students, searchQuery, statusFilter]);

  const stats = useMemo(() => {
    const total = students.length;
    const active = students.filter((s) => s.totalLessons - s.completedLessons > 0 && new Date(s.endDate) >= new Date()).length;
    const ending = students.filter((s) => {
      const rem = s.totalLessons - s.completedLessons;
      return rem > 0 && rem <= 2;
    }).length;
    return { total, active, ending };
  }, [students]);

  const getLayoutClass = () => {
    if (deviceMode === 'iphone') return 'max-w-[412px] mx-auto min-h-screen border-x border-white/10 shadow-2xl';
    if (deviceMode === 'ipad') return 'max-w-[900px] mx-auto min-h-screen border-x border-white/10 shadow-2xl';
    return 'w-full min-h-screen';
  };

  return (
    <div
      className="relative min-h-screen transition-colors duration-500 font-sans text-slate-100 overflow-x-hidden selection:bg-pink-500/30"
      style={{ background: customBg ? 'none' : currentTheme.bgGradient, color: currentTheme.text }}
    >
      {customBg && (
        <div className="fixed inset-0 bg-cover bg-center z-0 transition-all duration-300" style={{ backgroundImage: `url(${customBg})`, filter: `blur(${bgBlur}px)` }} />
      )}
      <div className="fixed inset-0 pointer-events-none z-0 transition-opacity duration-300" style={{ backgroundColor: '#000', opacity: bgDim / 100 }} />

      <div className={`relative z-10 flex flex-col ${getLayoutClass()}`}>
        <main className="flex-1 px-4 pt-4 pb-28 md:px-8">
          {activeTab === 'main' && (
            <DashboardView
              students={filteredStudents}
              stats={stats}
              searchQuery={searchQuery}
              setSearchQuery={setSearchQuery}
              statusFilter={statusFilter}
              setStatusFilter={setStatusFilter}
              currentTheme={currentTheme}
              borderRadius={borderRadius}
              bgBlur={bgBlur}
              onAddStudent={() => { setEditingStudent(null); setIsStudentModalOpen(true); }}
              onEditStudent={(s) => { setEditingStudent(s); setIsStudentModalOpen(true); }}
              onConfirmLesson={(s) => setLessonModalStudent(s)}
              onViewHistory={(s) => setHistoryStudent(s)}
              onOpenPwaGuide={() => setIsPwaModalOpen(true)}
            />
          )}

          {activeTab === 'calendar' && (
            <CalendarView
              students={students}
              lessons={lessons}
              currentTheme={currentTheme}
              borderRadius={borderRadius}
              onAddLessonRequest={(dateStr) => setCalendarModalDate(dateStr)}
            />
          )}

          {activeTab === 'settings' && (
            <SettingsView
              currentTheme={currentTheme}
              setActiveThemeId={setActiveThemeId}
              customBg={customBg}
              setCustomBg={setCustomBg}
              bgBlur={bgBlur}
              setBgBlur={setBgBlur}
              bgDim={bgDim}
              setBgDim={setBgDim}
              borderRadius={borderRadius}
              setBorderRadius={setBorderRadius}
              deviceMode={deviceMode}
              setDeviceMode={setDeviceMode}
              animationsEnabled={animationsEnabled}
              setAnimationsEnabled={setAnimationsEnabled}
              students={students}
              setStudents={setStudents}
              onOpenPwaGuide={() => setIsPwaModalOpen(true)}
            />
          )}
        </main>

        <BottomNavigation activeTab={activeTab} setActiveTab={setActiveTab} currentTheme={currentTheme} borderRadius={borderRadius} bgBlur={bgBlur} />
      </div>

      {/* MODALS */}
      {isStudentModalOpen && (
        <StudentFormModal
          student={editingStudent}
          onClose={() => { setIsStudentModalOpen(false); setEditingStudent(null); }}
          onSave={handleSaveStudent}
          currentTheme={currentTheme}
          borderRadius={borderRadius}
        />
      )}

      {lessonModalStudent && (
        <LessonConfirmationModal
          student={lessonModalStudent}
          onClose={() => setLessonModalStudent(null)}
          onConfirm={(date, note) => handleConfirmLesson(lessonModalStudent.id, date, note)}
          currentTheme={currentTheme}
          borderRadius={borderRadius}
        />
      )}

      {historyStudent && (
        <StudentHistoryModal
          student={historyStudent}
          onClose={() => setHistoryStudent(null)}
          onRevertLesson={(historyId) => {
            setStudents((prev) => prev.map((s) => s.id === historyStudent.id ? { ...s, completedLessons: Math.max(0, s.completedLessons - 1), history: s.history?.filter(h => h.id !== historyId) } : s));
          }}
          onDeleteStudent={() => handleDeleteStudent(historyStudent.id)}
          currentTheme={currentTheme}
          borderRadius={borderRadius}
        />
      )}

      {calendarModalDate && (
        <AddLessonModal
          date={calendarModalDate}
          students={students}
          onClose={() => setCalendarModalDate(null)}
          onAdd={handleAddLessonFromCalendar}
          currentTheme={currentTheme}
          borderRadius={borderRadius}
        />
      )}
    </div>
  );
}

// ==========================================
// 4. AUTH SCREEN (Email & Password + Zod)
// ==========================================
function AuthScreen() {
  const [isLogin, setIsLogin] = useState(true);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    const validation = authSchema.safeParse({ email, password });
    if (!validation.success) {
      setError(validation.error.errors[0].message);
      return;
    }

    setLoading(true);
    if (isLogin) {
      const { error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) setError(error.message);
    } else {
      const { error } = await supabase.auth.signUp({ email, password });
      if (error) {
        setError(error.message);
      } else {
        alert('Регистрация успешна! Теперь вы можете войти.');
        setIsLogin(true);
      }
    }
    setLoading(false);
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4 bg-gradient-to-br from-slate-950 via-purple-950 to-slate-900 text-slate-100">
      <div className="w-full max-w-md p-8 rounded-3xl bg-white/10 backdrop-blur-2xl border border-white/20 shadow-2xl space-y-6">
        <div className="text-center space-y-2">
          <div className="inline-flex p-3 rounded-2xl bg-pink-500/20 text-pink-400 border border-pink-500/30">
            <Sparkles size={32} />
          </div>
          <h1 className="text-2xl font-bold">Дашуля Tutor</h1>
          <p className="text-xs text-slate-400">Личный кабинет преподавателя</p>
        </div>

        {error && <div className="p-3 rounded-xl bg-red-500/20 border border-red-500/30 text-red-300 text-xs">{error}</div>}

        <form onSubmit={handleSubmit} className="space-y-4 text-xs">
          <div className="space-y-1">
            <label className="text-slate-300">Электронная почта</label>
            <div className="relative">
              <Mail className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="tutor@example.com"
                className="w-full pl-10 pr-4 py-3 bg-black/30 rounded-xl border border-white/10 focus:outline-none focus:border-pink-500 text-slate-100"
              />
            </div>
          </div>

          <div className="space-y-1">
            <label className="text-slate-300">Пароль</label>
            <div className="relative">
              <Lock className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full pl-10 pr-4 py-3 bg-black/30 rounded-xl border border-white/10 focus:outline-none focus:border-pink-500 text-slate-100"
              />
            </div>
          </div>

          <button
            type="submit"
            disabled={loading}
            className="w-full py-3 bg-pink-600 hover:bg-pink-500 font-semibold text-white rounded-xl shadow-lg shadow-pink-600/30 transition-all flex items-center justify-center gap-2"
          >
            <ShieldCheck size={18} />
            {loading ? 'Загрузка...' : isLogin ? 'Войти в систему' : 'Зарегистрироваться'}
          </button>
        </form>

        <div className="text-center text-xs">
          <button type="button" onClick={() => setIsLogin(!isLogin)} className="text-pink-400 hover:underline">
            {isLogin ? 'Нет аккаунта? Зарегистрироваться' : 'Уже есть аккаунт? Войти'}
          </button>
        </div>
      </div>
    </div>
  );
}

// ==========================================
// 5. DASHBOARD VIEW (MAIN TAB)
// ==========================================
function DashboardView({
  students,
  stats,
  searchQuery,
  setSearchQuery,
  statusFilter,
  setStatusFilter,
  currentTheme,
  borderRadius,
  bgBlur,
  onAddStudent,
  onEditStudent,
  onConfirmLesson,
  onViewHistory,
  onOpenPwaGuide
}) {
  const todayDate = new Date().toLocaleDateString('ru-RU', { weekday: 'long', day: 'numeric', month: 'long' });

  return (
    <div className="space-y-6 pt-4">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl md:text-3xl font-bold tracking-tight">Дашуля Tutor ❤️</h1>
          <p className="text-sm opacity-80 capitalize">{todayDate}</p>
        </div>

        <div className="flex items-center gap-2">
          <button onClick={onOpenPwaGuide} className="p-2.5 rounded-2xl bg-white/10 hover:bg-white/20 border border-white/20 transition-all flex items-center gap-2 text-xs font-medium">
            <Download className="w-4 h-4" />
            <span>PWA</span>
          </button>
          
          <button onClick={onAddStudent} style={{ borderRadius: `${borderRadius}px`, backgroundColor: currentTheme.primary }} className="px-4 py-2.5 text-white font-medium shadow-lg hover:opacity-90 transition-all flex items-center gap-2 text-sm">
            <Plus className="w-4 h-4" />
            <span>Добавить ученика</span>
          </button>
        </div>
      </div>

      {/* STATS */}
      <div className="grid grid-cols-3 gap-3">
        <div style={{ borderRadius: `${borderRadius}px`, backgroundColor: currentTheme.cardBg }} className="p-3.5 border border-white/10 shadow-lg flex flex-col justify-between">
          <div className="flex items-center justify-between text-xs opacity-75 mb-1"><span>Ученики</span><User className="w-4 h-4" /></div>
          <div className="text-xl font-bold">{stats.total}</div>
        </div>
        <div style={{ borderRadius: `${borderRadius}px`, backgroundColor: currentTheme.cardBg }} className="p-3.5 border border-white/10 shadow-lg flex flex-col justify-between">
          <div className="flex items-center justify-between text-xs opacity-75 mb-1"><span>Активные</span><CheckCircle2 className="w-4 h-4 text-emerald-400" /></div>
          <div className="text-xl font-bold text-emerald-400">{stats.active}</div>
        </div>
        <div style={{ borderRadius: `${borderRadius}px`, backgroundColor: currentTheme.cardBg }} className="p-3.5 border border-white/10 shadow-lg flex flex-col justify-between">
          <div className="flex items-center justify-between text-xs opacity-75 mb-1"><span>Истекают</span><AlertTriangle className="w-4 h-4 text-amber-400" /></div>
          <div className="text-xl font-bold text-amber-400">{stats.ending}</div>
        </div>
      </div>

      {/* SEARCH */}
      <div className="space-y-3">
        <div className="relative">
          <Search className="w-4 h-4 absolute left-3.5 top-1/2 -translate-y-1/2 opacity-50" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Поиск по имени или заметкам..."
            style={{ borderRadius: `${borderRadius}px` }}
            className="w-full pl-10 pr-4 py-2.5 bg-white/10 border border-white/20 text-sm focus:outline-none"
          />
        </div>
      </div>

      {/* STUDENT CARDS */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {students.map((student) => (
          <StudentCard
            key={student.id}
            student={student}
            currentTheme={currentTheme}
            borderRadius={borderRadius}
            bgBlur={bgBlur}
            onEdit={() => onEditStudent(student)}
            onConfirmLesson={() => onConfirmLesson(student)}
            onViewHistory={() => onViewHistory(student)}
          />
        ))}
      </div>
    </div>
  );
}

function StudentCard({ student, currentTheme, borderRadius, bgBlur, onEdit, onConfirmLesson, onViewHistory }) {
  const percent = Math.min(100, Math.round((student.completedLessons / (student.totalLessons || 1)) * 100));
  const remaining = Math.max(0, student.totalLessons - student.completedLessons);

  return (
    <div
      style={{ borderRadius: `${borderRadius}px`, backgroundColor: currentTheme.cardBg, backdropFilter: `blur(${bgBlur}px)` }}
      className="p-4 border border-white/10 shadow-lg space-y-3 relative overflow-hidden transition-all hover:scale-[1.01]"
    >
      <div className="absolute top-0 left-0 w-1.5 h-full" style={{ backgroundColor: student.color || '#ec4899' }} />

      <div className="flex justify-between items-start">
        <div>
          <div className="flex items-center gap-2">
            <h3 className="font-bold text-base">{student.name}</h3>
            <span className="text-xs px-2 py-0.5 rounded-full bg-white/10">{student.language === 'English' ? '🇬🇧 EN' : '🇸🇦 AR'}</span>
          </div>
          <p className="text-xs opacity-60">Абонемент до: {student.endDate}</p>
        </div>
        <button onClick={onEdit} className="p-1.5 rounded-xl bg-white/10 hover:bg-white/20"><Edit3 className="w-3.5 h-3.5" /></button>
      </div>

      <div className="space-y-1">
        <div className="flex justify-between text-xs font-medium">
          <span>Проведено: {student.completedLessons} / {student.totalLessons}</span>
          <span>Осталось: {remaining}</span>
        </div>
        <div className="w-full h-2 bg-black/20 rounded-full overflow-hidden">
          <div className="h-full rounded-full transition-all" style={{ width: `${percent}%`, backgroundColor: student.color || '#ec4899' }} />
        </div>
      </div>

      <div className="flex items-center gap-2 pt-2 border-t border-white/10">
        <button
          onClick={onConfirmLesson}
          disabled={remaining <= 0}
          style={{ borderRadius: `${borderRadius - 6}px`, backgroundColor: remaining > 0 ? currentTheme.primary : 'rgba(255,255,255,0.1)' }}
          className="flex-1 py-2 text-xs font-medium text-white shadow-md flex items-center justify-center gap-1.5 disabled:opacity-40"
        >
          <CheckCircle2 className="w-3.5 h-3.5" /> + Провести урок
        </button>
        <button onClick={onViewHistory} style={{ borderRadius: `${borderRadius - 6}px` }} className="py-2 px-3 bg-white/10 hover:bg-white/20 border border-white/20 text-xs flex items-center gap-1">
          <History className="w-3.5 h-3.5" /> История
        </button>
      </div>
    </div>
  );
}

// ==========================================
// 6. SMART CALENDAR VIEW (With Color Badges & Auto-Shrink)
// ==========================================
function CalendarView({ students, lessons, currentTheme, borderRadius, onAddLessonRequest }) {
  const [currentDate, setCurrentDate] = useState(new Date());

  const year = currentDate.getFullYear();
  const month = currentDate.getMonth();

  const daysInMonth = new Date(year, month + 1, 0).getDate();
  const firstDayIndex = (new Date(year, month, 1).getDay() + 6) % 7; // Пн старт

  const monthName = currentDate.toLocaleString('ru-RU', { month: 'long', year: 'numeric' });

  return (
    <div className="space-y-4 pt-4">
      <div className="flex items-center justify-between bg-white/5 p-4 rounded-2xl border border-white/10 backdrop-blur-md">
        <h2 className="text-base font-bold capitalize">{monthName}</h2>
        <div className="flex gap-2">
          <button onClick={() => setCurrentDate(new Date(year, month - 1, 1))} className="p-2 bg-white/10 rounded-xl hover:bg-white/20"><CaretLeft size={16} /></button>
          <button onClick={() => setCurrentDate(new Date(year, month + 1, 1))} className="p-2 bg-white/10 rounded-xl hover:bg-white/20"><CaretRight size={16} /></button>
        </div>
      </div>

      <div className="grid grid-cols-7 gap-1 text-center text-xs font-semibold text-slate-400">
        {['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'].map(d => <div key={d}>{d}</div>)}
      </div>

      <div className="grid grid-cols-7 gap-1.5">
        {/* Пустые ячейки для смещения месяца */}
        {Array.from({ length: firstDayIndex }).map((_, i) => (
          <div key={`empty-${i}`} className="min-h-[85px] p-1 rounded-xl bg-white/5 opacity-20" />
        ))}

        {/* Дни месяца */}
        {Array.from({ length: daysInMonth }).map((_, i) => {
          const dayNum = i + 1;
          const dayStr = `${year}-${String(month + 1).padStart(2, '0')}-${String(dayNum).padStart(2, '0')}`;
          const dayLessons = lessons.filter(l => l.date === dayStr);

          return (
            <div
              key={dayStr}
              onClick={() => onAddLessonRequest(dayStr)}
              className="min-h-[90px] p-1.5 rounded-xl bg-white/5 border border-white/10 hover:border-pink-500 cursor-pointer flex flex-col justify-between overflow-hidden transition-all"
            >
              <span className="text-xs font-semibold">{dayNum}</span>

              {/* Умные прямоугольники с автоматическим сжатием */}
              <div className="space-y-1 overflow-y-auto max-h-[60px] no-scrollbar">
                {dayLessons.map(l => {
                  const student = students.find(s => s.id === l.studentId);
                  const color = student?.color || currentTheme.primary;
                  return (
                    <div
                      key={l.id}
                      style={{ backgroundColor: color }}
                      className="px-1.5 py-0.5 rounded text-[9px] font-medium text-white truncate shadow-sm flex justify-between"
                      title={`${l.time} - ${student?.name}`}
                    >
                      <span>{l.time}</span>
                      <span className="truncate ml-1">{student?.name.split(' ')[0]}</span>
                    </div>
                  );
                })}
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ==========================================
// 7. SETTINGS VIEW (With Logout)
// ==========================================
function SettingsView({
  currentTheme,
  setActiveThemeId,
  customBg,
  setCustomBg,
  bgBlur,
  setBgBlur,
  bgDim,
  setBgDim,
  borderRadius,
  setBorderRadius,
  deviceMode,
  setDeviceMode,
  animationsEnabled,
  setAnimationsEnabled,
  students,
  setStudents,
  onOpenPwaGuide
}) {
  const fileInputRef = useRef(null);

  const handleLogout = async () => {
    await supabase.auth.signOut();
  };

  return (
    <div className="space-y-6 pt-4 max-w-lg mx-auto">
      <div>
        <h1 className="text-2xl font-bold">Настройки</h1>
        <p className="text-xs opacity-70">Персонализация и управление личным кабинетом</p>
      </div>

      {/* Темы оформления */}
      <div style={{ borderRadius: `${borderRadius}px`, backgroundColor: currentTheme.cardBg }} className="p-5 border border-white/10 shadow-xl space-y-4">
        <h2 className="font-bold text-sm flex items-center gap-2"><Sparkles size={18} /> Выбор темы оформления</h2>
        <div className="grid grid-cols-2 gap-2">
          {THEMES.map(t => (
            <button
              key={t.id}
              onClick={() => setActiveThemeId(t.id)}
              style={{ background: t.bgGradient, borderRadius: `${borderRadius - 6}px` }}
              className={`p-3 text-left border ${t.id === currentTheme.id ? 'ring-2 ring-white border-white' : 'border-white/20'}`}
            >
              <span className="text-xl">{t.icon}</span>
              <div className="mt-1 text-xs font-semibold text-white">{t.name}</div>
            </button>
          ))}
        </div>
      </div>

      {/* Личный кабинет и выход */}
      <div style={{ borderRadius: `${borderRadius}px`, backgroundColor: currentTheme.cardBg }} className="p-5 border border-white/10 shadow-xl space-y-4">
        <h2 className="font-bold text-sm flex items-center gap-2"><ShieldCheck size={18} /> Безопасность и сессия</h2>
        <button
          onClick={handleLogout}
          className="w-full py-3 bg-red-500/20 hover:bg-red-500/30 border border-red-500/30 text-red-300 rounded-xl text-xs font-semibold flex items-center justify-center gap-2 transition-all"
        >
          <LogOut size={16} /> Выйти из личного кабинета
        </button>
      </div>
    </div>
  );
}

// ==========================================
// 8. BOTTOM NAVIGATION BAR
// ==========================================
function BottomNavigation({ activeTab, setActiveTab, currentTheme, borderRadius, bgBlur }) {
  const tabs = [
    { id: 'main', label: 'Главная', icon: Home },
    { id: 'calendar', label: 'Календарь', icon: CalendarIcon },
    { id: 'settings', label: 'Настройки', icon: SettingsIcon },
  ];

  return (
    <nav
      className="fixed bottom-3 left-1/2 -translate-x-1/2 z-40 w-[92%] max-w-md transition-all duration-300"
      style={{ borderRadius: `${borderRadius}px`, backgroundColor: currentTheme.glassBg, backdropFilter: `blur(${bgBlur}px)`, borderColor: currentTheme.glassBorder, borderWidth: '1px' }}
    >
      <div className="flex items-center justify-around py-2 px-3">
        {tabs.map((tab) => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex flex-col items-center gap-1 px-5 py-1.5 rounded-2xl transition-all duration-300 ${isActive ? 'scale-105' : 'opacity-60 hover:opacity-100'}`}
              style={{ backgroundColor: isActive ? currentTheme.primary : 'transparent', color: isActive ? '#ffffff' : currentTheme.text }}
            >
              <Icon size={20} />
              <span className="text-[11px] font-medium">{tab.label}</span>
            </button>
          );
        })}
      </div>
    </nav>
  );
}

// ==========================================
// 9. MODALS (Student Form, Lesson Add, History)
// ==========================================
function StudentFormModal({ student, onClose, onSave, currentTheme, borderRadius }) {
  const [formData, setFormData] = useState({
    name: student?.name || '',
    language: student?.language || 'English',
    totalLessons: student?.totalLessons || 10,
    startDate: student?.startDate || new Date().toISOString().slice(0, 10),
    endDate: student?.endDate || new Date(Date.now() + 30 * 86400000).toISOString().slice(0, 10),
    price: student?.price || 15000,
    duration: student?.duration || 60,
    color: student?.color || '#ec4899',
    notes: student?.notes || ''
  });

  const handleSubmit = (e) => {
    e.preventDefault();
    const result = studentSchema.safeParse(formData);
    if (!result.success) {
      alert(result.error.errors[0].message);
      return;
    }
    onSave(formData);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
      <div style={{ borderRadius: `${borderRadius}px`, backgroundColor: currentTheme.cardBg }} className="w-full max-w-lg border border-white/20 p-6 shadow-2xl space-y-4 max-h-[90vh] overflow-y-auto">
        <div className="flex justify-between items-center border-b border-white/10 pb-3">
          <h2 className="text-lg font-bold">{student ? 'Редактировать ученика' : 'Новый ученик'}</h2>
          <button onClick={onClose} className="p-1 rounded-full hover:bg-white/10"><X size={18} /></button>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4 text-xs">
          <div>
            <label className="block mb-1 opacity-80">ФИО Ученика *</label>
            <input type="text" required value={formData.name} onChange={e => setFormData({ ...formData, name: e.target.value })} className="w-full p-2.5 bg-white/10 rounded-xl border border-white/20" />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block mb-1 opacity-80">Язык</label>
              <select value={formData.language} onChange={e => setFormData({ ...formData, language: e.target.value })} className="w-full p-2.5 bg-white/10 rounded-xl border border-white/20 text-black">
                <option value="English">English</option>
                <option value="Arabic">Arabic</option>
              </select>
            </div>
            <div>
              <label className="block mb-1 opacity-80">Цвет в календаре</label>
              <input type="color" value={formData.color} onChange={e => setFormData({ ...formData, color: e.target.value })} className="w-full h-10 p-1 bg-white/10 rounded-xl border border-white/20 cursor-pointer" />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block mb-1 opacity-80">Всего занятий</label>
              <input type="number" min="1" value={formData.totalLessons} onChange={e => setFormData({ ...formData, totalLessons: Number(e.target.value) })} className="w-full p-2.5 bg-white/10 rounded-xl border border-white/20" />
            </div>
            <div>
              <label className="block mb-1 opacity-80">Стоимость (руб)</label>
              <input type="number" value={formData.price} onChange={e => setFormData({ ...formData, price: Number(e.target.value) })} className="w-full p-2.5 bg-white/10 rounded-xl border border-white/20" />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block mb-1 opacity-80">Начало абонемента</label>
              <input type="date" value={formData.startDate} onChange={e => setFormData({ ...formData, startDate: e.target.value })} className="w-full p-2.5 bg-white/10 rounded-xl border border-white/20" />
            </div>
            <div>
              <label className="block mb-1 opacity-80">Конец абонемента</label>
              <input type="date" value={formData.endDate} onChange={e => setFormData({ ...formData, endDate: e.target.value })} className="w-full p-2.5 bg-white/10 rounded-xl border border-white/20" />
            </div>
          </div>

          <div>
            <label className="block mb-1 opacity-80">Заметки</label>
            <textarea rows="2" value={formData.notes} onChange={e => setFormData({ ...formData, notes: e.target.value })} className="w-full p-2.5 bg-white/10 rounded-xl border border-white/20" />
          </div>

          <button type="submit" style={{ backgroundColor: currentTheme.primary }} className="w-full py-3 text-white rounded-xl font-semibold shadow-md">Сохранить</button>
        </form>
      </div>
    </div>
  );
}

function AddLessonModal({ date, students, onClose, onAdd, currentTheme, borderRadius }) {
  const [studentId, setStudentId] = useState(students[0]?.id || '');
  const [time, setTime] = useState('12:00');
  const [topic, setTopic] = useState('');

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
      <div style={{ borderRadius: `${borderRadius}px`, backgroundColor: currentTheme.cardBg }} className="w-full max-w-sm border border-white/20 p-5 shadow-2xl space-y-4 text-xs">
        <div className="flex justify-between items-center">
          <h3 className="font-bold text-sm">Добавить урок на {date}</h3>
          <button onClick={onClose}><X size={16} /></button>
        </div>

        <form onSubmit={e => { e.preventDefault(); onAdd({ studentId, date, time, topic }); onClose(); }} className="space-y-3">
          <div>
            <label className="block mb-1 opacity-80">Ученик</label>
            <select value={studentId} onChange={e => setStudentId(e.target.value)} className="w-full p-2.5 bg-white/10 rounded-xl border border-white/20 text-black">
              {students.map(s => <option key={s.id} value={s.id}>{s.name}</option>)}
            </select>
          </div>
          <div>
            <label className="block mb-1 opacity-80">Время</label>
            <input type="time" value={time} onChange={e => setTime(e.target.value)} className="w-full p-2.5 bg-white/10 rounded-xl border border-white/20" />
          </div>
          <div>
            <label className="block mb-1 opacity-80">Тема урока</label>
            <input type="text" value={topic} onChange={e => setTopic(e.target.value)} placeholder="Тема..." className="w-full p-2.5 bg-white/10 rounded-xl border border-white/20" />
          </div>
          <button type="submit" style={{ backgroundColor: currentTheme.primary }} className="w-full py-2.5 text-white font-semibold rounded-xl">Добавить в календарь</button>
        </form>
      </div>
    </div>
  );
}

function LessonConfirmationModal({ student, onClose, onConfirm, currentTheme, borderRadius }) {
  const [note, setNote] = useState('');
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
      <div style={{ borderRadius: `${borderRadius}px`, backgroundColor: currentTheme.cardBg }} className="w-full max-w-sm border border-white/20 p-5 shadow-2xl space-y-4 text-xs">
        <h3 className="font-bold text-sm">Проведение урока</h3>
        <p>Списать 1 занятие у <strong>{student.name}</strong>?</p>
        <input type="text" value={note} onChange={e => setNote(e.target.value)} placeholder="Заметка к уроку..." className="w-full p-2.5 bg-white/10 rounded-xl border border-white/20" />
        <div className="flex gap-2">
          <button onClick={onClose} className="flex-1 py-2 bg-white/10 rounded-xl">Отмена</button>
          <button onClick={() => onConfirm(new Date().toISOString().slice(0, 10), note)} style={{ backgroundColor: currentTheme.primary }} className="flex-1 py-2 text-white rounded-xl">Подтвердить</button>
        </div>
      </div>
    </div>
  );
}

function StudentHistoryModal({ student, onClose, onRevertLesson, onDeleteStudent, currentTheme, borderRadius }) {
  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-sm">
      <div style={{ borderRadius: `${borderRadius}px`, backgroundColor: currentTheme.cardBg }} className="w-full max-w-md border border-white/20 p-5 shadow-2xl space-y-4 max-h-[80vh] flex flex-col text-xs">
        <div className="flex justify-between items-center border-b border-white/10 pb-2">
          <h3 className="font-bold text-sm">{student.name} — История</h3>
          <button onClick={onClose}><X size={16} /></button>
        </div>
        <div className="flex-1 overflow-y-auto space-y-2">
          {!student.history || student.history.length === 0 ? <p className="opacity-50 text-center py-4">История пуста</p> : student.history.map(h => (
            <div key={h.id} className="p-2.5 bg-white/5 border border-white/10 rounded-xl flex justify-between items-center">
              <div>
                <div className="font-medium text-pink-300">{h.date}</div>
                <div>{h.note}</div>
              </div>
              <button onClick={() => onRevertLesson(h.id)} className="p-1 text-red-400 hover:bg-red-500/10 rounded"><RotateCcw size={14} /></button>
            </div>
          ))}
        </div>
        <div className="flex justify-between pt-2 border-t border-white/10">
          <button onClick={onDeleteStudent} className="px-3 py-1.5 bg-red-500/20 text-red-400 border border-red-500/30 rounded-xl">Удалить ученика</button>
          <button onClick={onClose} className="px-4 py-1.5 bg-white/10 rounded-xl">Закрыть</button>
        </div>
      </div>
    </div>
  );
}
